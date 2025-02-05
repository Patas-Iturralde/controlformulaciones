import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://192.168.0.116:5000"; // IP de la api ojo debemos estar conectados en la VPN

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/api/login");
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({"username": username, "password": password});

    try {
      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["success"] == true) {
          return {
            "success": true,
            "user": data["user"], // Contiene el usuario con rol, userId, etc.
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
    final headers = {"accept": "application/json"};

    try {
      final response = await http.get(url, headers: headers);
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
}