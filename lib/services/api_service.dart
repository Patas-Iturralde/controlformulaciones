import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart';

class ApiService {
  final String baseUrl = "http://192.168.0.116:5000";

  Future<Map<String, String>> _getHeaders({bool includeToken = true}) async {
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "accept": "application/json"
    };

    if (includeToken) {
      final tokenService = await TokenService.getInstance();
      final token = tokenService.getToken();
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    return headers;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/api/login");
    final headers = await _getHeaders(includeToken: false);
    final body = jsonEncode({"username": username, "password": password});

    try {
      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["success"] == true) {
          // Guardar el token si existe en la respuesta
          if (data["token"] != null) {
            final tokenService = await TokenService.getInstance();
            await tokenService.saveToken(data["token"]);
            await tokenService.saveUserData(data["user"]);
          }

          return {
            "success": true,
            "user": data["user"],
            "message": null,
          };
        } else {
          return {
            "success": false,
            "user": null,
            "message": data["message"] ?? "Error desconocido",
          };
        }
      } else {
        return {
          "success": false,
          "user": null,
          "message": "Error en la conexión con el servidor",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "user": null,
        "message": "Error de conexión: $e",
      };
    }
  }

  Future<Map<String, dynamic>> getPesajesAbiertos() async {
    final url = Uri.parse("$baseUrl/api/pesajes_abiertos");
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 401) {
        // Token expirado o inválido
        final tokenService = await TokenService.getInstance();
        await tokenService.logout();
        return {
          "success": false,
          "data": null,
          "message": "Sesión expirada",
          "sessionExpired": true
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "data": data,
          "message": null,
        };
      } else {
        return {
          "success": false,
          "data": null,
          "message": "Error al obtener pesajes abiertos",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "data": null,
        "message": "Error de conexión: $e",
      };
    }
  }

  Future<Map<String, dynamic>> getProductosQuimicos() async {
    final url = Uri.parse("$baseUrl/api/productos_quimicos");
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 401) {
        // Token expirado o inválido
        final tokenService = await TokenService.getInstance();
        await tokenService.logout();
        return {
          "success": false,
          "data": null,
          "message": "Sesión expirada",
          "sessionExpired": true
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["success"]) {
          return {
            "success": true,
            "data": data["data"], // Lista de productos químicos
            "total": data["total"],
            "message": null,
          };
        } else {
          return {
            "success": false,
            "data": [],
            "message": data["message"] ?? "No hay productos disponibles",
          };
        }
      } else {
        return {
          "success": false,
          "data": null,
          "message": "Error al obtener productos químicos",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "data": null,
        "message": "Error de conexión: $e",
      };
    }
  }
}