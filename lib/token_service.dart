import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _tokenExpirationKey = 'token_expiration';
  static const String _userDataKey = 'user_data';
  
  static TokenService? _instance;
  static SharedPreferences? _prefs;
  
  TokenService._();
  
  static Future<TokenService> getInstance() async {
    if (_instance == null) {
      _instance = TokenService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  Future<bool> saveToken(String token) async {
    try {
      final expirationTime = DateTime.now().add(const Duration(hours: 6)).millisecondsSinceEpoch;
      
      final results = await Future.wait<bool>([
        _prefs?.setString(_tokenKey, token) ?? Future.value(false),
        _prefs?.setInt(_tokenExpirationKey, expirationTime) ?? Future.value(false),
      ]);
      
      return results.every((success) => success);
    } catch (e) {
      print('Error guardando token: $e');
      return false;
    }
  }

  bool hasValidToken() {
    try {
      final token = _prefs?.getString(_tokenKey);
      final expirationTime = _prefs?.getInt(_tokenExpirationKey);
      
      if (token == null || expirationTime == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      return now < expirationTime;
    } catch (e) {
      print('Error verificando token: $e');
      return false;
    }
  }

  bool isTokenExpiringSoon() {
    try {
      final expirationTime = _prefs?.getInt(_tokenExpirationKey);
      if (expirationTime == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      final timeToExpire = expirationTime - now;
      
      // Retorna true si faltan menos de 30 minutos
      return timeToExpire < 30 * 60 * 1000;
    } catch (e) {
      return false;
    }
  }

  String? getToken() {
    if (hasValidToken()) {
      return _prefs?.getString(_tokenKey);
    }
    return null;
  }

  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    return await _prefs?.setString(_userDataKey, json.encode(userData)) ?? false;
  }

  Map<String, dynamic>? getUserData() {
    final userData = _prefs?.getString(_userDataKey);
    if (userData != null) {
      try {
        return json.decode(userData);
      } catch (e) {
        print('Error al convertir userData: $e');
        return null;
      }
    }
    return null;
  }

  Future<bool> logout() async {
    final results = await Future.wait<bool>([
      _prefs?.remove(_tokenKey) ?? Future.value(false),
      _prefs?.remove(_tokenExpirationKey) ?? Future.value(false),
      _prefs?.remove(_userDataKey) ?? Future.value(false),
    ]);
    return results.every((success) => success);
  }
}