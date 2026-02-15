import 'package:dio/dio.dart';

/// Restituisce un messaggio sicuro da mostrare all'utente. MAI mostrare DioException o stack trace.
/// Con l'interceptor globale in api_client, i DioException hanno già message user-friendly.
String userFriendlyErrorMessage(dynamic e) {
  if (e is DioException) {
    final msg = e.message;
    return (msg != null && msg.isNotEmpty) ? msg : 'Errore di connessione. Verifica la rete.';
  }
  return 'Si è verificato un errore. Riprova.';
}
