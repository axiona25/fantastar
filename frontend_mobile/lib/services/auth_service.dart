import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/constants.dart';
import '../models/token.dart';
import '../models/user.dart';
import 'api_client.dart';

/// Servizio auth: login, register, refresh, logout, getCurrentUser.
/// Persiste token in SharedPreferences; notifica onUnauthorized per redirect login.
class AuthService {
  AuthService() : _dio = null {
    _init();
  }

  Dio? _dio;
  SharedPreferences? _prefs;
  void Function()? onUnauthorized;

  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Dio get dio {
    if (_dio == null) {
      _dio = createApiClient(this);
    }
    return _dio!;
  }

  Future<String?> getAccessToken() async {
    await _init();
    return _prefs!.getString(kKeyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    await _init();
    return _prefs!.getString(kKeyRefreshToken);
  }

  Future<void> saveTokens(TokenModel token) async {
    await _init();
    await _prefs!.setString(kKeyAccessToken, token.accessToken);
    await _prefs!.setString(kKeyRefreshToken, token.refreshToken);
  }

  Future<void> clearTokens() async {
    await _init();
    await _prefs!.remove(kKeyAccessToken);
    await _prefs!.remove(kKeyRefreshToken);
    await _prefs!.remove(kKeyUserId);
  }

  Future<bool> tryRefreshToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final response = await Dio(BaseOptions(baseUrl: kApiBaseUrl)).post(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final token = TokenModel.fromJson(response.data as Map<String, dynamic>);
      await saveTokens(token);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<TokenModel> login(String email, String password) async {
    final response = await dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final token = TokenModel.fromJson(response.data as Map<String, dynamic>);
    await saveTokens(token);
    return token;
  }

  Future<UserModel> register(String email, String username, String password) async {
    final response = await dio.post(
      '/auth/register',
      data: {
        'email': email,
        'username': username,
        'password': password,
      },
    );
    final user = UserModel.fromJson(response.data as Map<String, dynamic>);
    await login(email, password);
    return user;
  }

  Future<UserModel?> getMe() async {
    try {
      final response = await dio.get('/auth/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await clearTokens();
    _dio = null;
  }

  /// Registra il token FCM per ricevere push notification.
  Future<void> registerFcmToken(String fcmToken) async {
    if (fcmToken.isEmpty) return;
    try {
      await dio.post('/auth/fcm-token', data: {'fcm_token': fcmToken});
    } catch (_) {
      // ignore if backend not ready or 401
    }
  }

  /// Step 1 recupero password: richiedi OTP (backend può restituire phone per Firebase).
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await dio.post('/auth/forgot-password', data: {'email': email});
    return response.data as Map<String, dynamic>;
  }

  /// Step 2: verifica OTP e ottieni reset_token.
  Future<String> verifyOtp(String email, String otpCode) async {
    final response = await dio.post(
      '/auth/verify-otp',
      data: {'email': email, 'otp_code': otpCode},
    );
    final data = response.data as Map<String, dynamic>;
    return data['reset_token'] as String;
  }

  /// Step 2 alternativo: verifica tramite Firebase Phone Auth id_token.
  Future<String> verifyPhoneReset(String idToken) async {
    final response = await dio.post(
      '/auth/verify-phone-reset',
      data: {'id_token': idToken},
    );
    final data = response.data as Map<String, dynamic>;
    return data['reset_token'] as String;
  }

  /// Step 3: imposta nuova password con reset_token.
  Future<void> resetPassword(String resetToken, String newPassword) async {
    await dio.post(
      '/auth/reset-password',
      data: {
        'reset_token': resetToken,
        'new_password': newPassword,
        'confirm_password': newPassword,
      },
    );
  }
}
