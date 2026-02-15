import 'package:dio/dio.dart';

import '../app/constants.dart';
import 'auth_service.dart';

/// Client HTTP con base URL e interceptor JWT.
/// Gestisce 401 → il chiamante (AuthProvider) può reindirizzare al login.
Dio createApiClient(AuthService authService) {
  final dio = Dio(BaseOptions(
    baseUrl: kApiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await authService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final refreshed = await authService.tryRefreshToken();
        if (refreshed) {
          final opts = error.requestOptions;
          final token = await authService.getAccessToken();
          opts.headers['Authorization'] = 'Bearer $token';
          try {
            final response = await dio.fetch(opts);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(_userFriendlyDioException(e is DioException ? e : error));
          }
        }
        authService.onUnauthorized?.call();
      }
      return handler.next(error);
    },
  ));

  // Interceptor che converte TUTTI gli errori in messaggi user-friendly (mai mostrare DioException grezzo)
  dio.interceptors.add(InterceptorsWrapper(
    onError: (DioException e, handler) {
      handler.next(_userFriendlyDioException(e));
    },
  ));

  return dio;
}

/// Converte DioException in una con messaggio sicuro per l'utente. Usato dall'interceptor globale.
DioException _userFriendlyDioException(DioException e) {
  final String msg;
  switch (e.response?.statusCode) {
    case 400:
      msg = e.response?.data is Map
          ? (e.response?.data['detail']?.toString() ?? 'Richiesta non valida')
          : 'Richiesta non valida';
      break;
    case 401:
      msg = 'Sessione scaduta. Effettua di nuovo il login.';
      break;
    case 403:
      msg = 'Non hai i permessi per questa operazione.';
      break;
    case 404:
      msg = 'Risorsa non trovata.';
      break;
    case 500:
      msg = 'Errore del server. Riprova tra poco.';
      break;
    default:
      msg = 'Errore di connessione. Verifica la rete.';
  }
  return DioException(
    requestOptions: e.requestOptions,
    response: e.response,
    type: e.type,
    error: msg,
    message: msg,
  );
}
