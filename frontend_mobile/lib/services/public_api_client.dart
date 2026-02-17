import 'package:dio/dio.dart';

import '../app/constants.dart';

/// Client HTTP per endpoint pubblici (news, standings, stats) che NON richiedono JWT.
/// Usa questo invece di auth.dio per evitare 401 quando l'utente non è loggato o usa login mock.
Dio? _publicDio;

Dio get publicApiClient {
  _publicDio ??= Dio(BaseOptions(
    baseUrl: kApiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));
  return _publicDio!;
}
