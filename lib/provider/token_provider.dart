// lib/provider/token_provider.dart

import 'package:flutter/foundation.dart';
import '../services/token_service.dart';

class TokenProvider extends ChangeNotifier {
  late TokenService _tokenService;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  TokenProvider() {
    _init();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> _init() async {
    try {
      _tokenService = await TokenService.getInstance();
      await _checkAuthStatus();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkAuthStatus() async {
    _isAuthenticated = _tokenService.hasValidToken();
    
    // Verificar si el token está por expirar
    if (_isAuthenticated && _tokenService.isTokenExpiringSoon()) {
      // Aquí podrías implementar la lógica para refrescar el token
      // Por ejemplo, hacer una llamada a tu API para obtener un nuevo token
      print('Token está por expirar');
    }
    
    notifyListeners();
  }

  Future<void> updateToken(String token) async {
    await _tokenService.saveToken(token);
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> updateUserData(Map<String, dynamic> userData) async {
    await _tokenService.saveUserData(userData);
    notifyListeners();
  }

  Map<String, dynamic>? getUserData() {
    return _tokenService.getUserData();
  }

  String? getToken() {
    return _tokenService.getToken();
  }

  Future<void> logout() async {
    await _tokenService.logout();
    _isAuthenticated = false;
    notifyListeners();
  }

  // Método para verificar el estado de autenticación manualmente
  Future<void> checkAuth() async {
    await _checkAuthStatus();
  }

  // Método para manejar errores de token expirado
  Future<void> handleTokenExpired() async {
    await logout();
    notifyListeners();
  }
}