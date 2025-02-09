import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart';

class ApiService {
  final String baseUrl = "http://192.168.0.116:5000";

  Future<Map<String, String>> _getHeaders({bool includeToken = true}) async {
    Map<String, String> headers = {
      "Content-Type": "application/json; charset=UTF-8",
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
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        if (data["success"] == true) {
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
      String errorMessage = "No hay conexión a internet";
      
      if (e.toString().contains("SocketException")) {
        errorMessage = "No hay conexión a internet. Por favor, verifica tu conexión";
      }

      return {
        "success": false,
        "user": null,
        "message": errorMessage,
      };
    }
  }

  Future<Map<String, dynamic>> getPesajesAbiertos() async {
    final url = Uri.parse("$baseUrl/api/pesajes_abiertos");
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 401) {
        final tokenService = await TokenService.getInstance();
        await tokenService.logout();
        return {
          "success": false,
          "data": null,
          "message": "Sesión expirada",
          "sessionExpired": true
        };
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

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
      String errorMessage = "No hay conexión a internet";
      
      if (e.toString().contains("SocketException")) {
        errorMessage = "No hay conexión a internet. Por favor, verifica tu conexión";
      }

      return {
        "success": false,
        "data": null,
        "message": errorMessage,
      };
    }
  }

  Future<Map<String, dynamic>> getProductosQuimicos() async {
    final url = Uri.parse("$baseUrl/api/productos_quimicos");
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 401) {
        final tokenService = await TokenService.getInstance();
        await tokenService.logout();
        return {
          "success": false,
          "data": null,
          "message": "Sesión expirada",
          "sessionExpired": true
        };
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        if (data["success"]) {
          return {
            "success": true,
            "data": data["data"],
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
      String errorMessage = "No hay conexión a internet";
      
      if (e.toString().contains("SocketException")) {
        errorMessage = "No hay conexión a internet. Por favor, verifica tu conexión";
      }

      return {
        "success": false,
        "data": null,
        "message": errorMessage,
      };
    }
  }

  Future<Map<String, dynamic>> getOperaciones() async {
    final url = Uri.parse("$baseUrl/api/operaciones");
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 401) {
        final tokenService = await TokenService.getInstance();
        await tokenService.logout();
        return {
          "success": false,
          "data": null,
          "message": "Sesión expirada",
          "sessionExpired": true
        };
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        if (data["success"]) {
          return {
            "success": true,
            "data": data["data"],
            "total": data["total"],
            "message": null,
          };
        } else {
          return {
            "success": false,
            "data": [],
            "message": data["message"] ?? "No hay operaciones disponibles",
          };
        }
      } else {
        return {
          "success": false,
          "data": null,
          "message": "Error al obtener operaciones",
        };
      }
    } catch (e) {
      String errorMessage = "No hay conexión a internet";
      
      if (e.toString().contains("SocketException")) {
        errorMessage = "No hay conexión a internet. Por favor, verifica tu conexión";
      }

      return {
        "success": false,
        "data": null,
        "message": errorMessage,
      };
    }
  }

  Future<Map<String, dynamic>> sincronizarPesaje({
    required Map<String, dynamic> proceso,
    required List<Map<String, dynamic>> secuencias,
  }) async {
    final url = Uri.parse("$baseUrl/api/sincronizar_pesaje");
    final headers = await _getHeaders();

    try {
      final body = jsonEncode({
        "proceso": {
          "nrOp": proceso['nrOp'],
          "codProducto": proceso['codProducto'],
          "producto": proceso['producto'],
          "numeroPesaje": proceso['numeroPesaje'],
          "fecha_proceso": proceso['fecha_proceso'],
          "maquina": proceso['maquina'],
          "situacion": proceso['situacion'],
        },
        "secuencias": secuencias.map((secuencia) => {
          "secuencia": secuencia['secuencia'],
          "instruccion": secuencia['instruccion'],
          "producto": secuencia['producto'],
          "codigo_escaneado": secuencia['codigo_escaneado'],
          "ctd_explosion": secuencia['ctd_explosion'],
          "temperatura": secuencia['temperatura'],
          "tiempo": secuencia['tiempo'],
          "observacion": secuencia['observacion'],
          "hora_inicio": secuencia['hora_inicio'],
          "hora_fin": secuencia['hora_fin'],
        }).toList(),
      });

      final response = await http.post(url, headers: headers, body: body);
      
      if (response.statusCode == 401) {
        final tokenService = await TokenService.getInstance();
        await tokenService.logout();
        return {
          "success": false,
          "message": "Sesión expirada",
          "sessionExpired": true
        };
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": "Datos sincronizados correctamente",
        };
      } else {
        return {
          "success": false,
          "message": data["detail"] ?? "Error al sincronizar los datos",
        };
      }
    } catch (e) {
      String errorMessage = "Error de conexión";
      
      if (e.toString().contains("SocketException")) {
        errorMessage = "No hay conexión a internet. Por favor, verifica tu conexión";
      }

      return {
        "success": false,
        "message": errorMessage,
      };
    }
  }

  Future<Map<String, dynamic>> getProcesosRemoto() async {
    final url = Uri.parse("$baseUrl/api/procesos");
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 401) {
        final tokenService = await TokenService.getInstance();
        await tokenService.logout();
        return {
          "success": false,
          "data": null,
          "message": "Sesión expirada",
          "sessionExpired": true
        };
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        if (data["success"]) {
          return {
            "success": true,
            "data": data["data"],
            "message": null,
          };
        } else {
          return {
            "success": false,
            "data": [],
            "message": data["message"] ?? "No hay procesos disponibles",
          };
        }
      } else {
        return {
          "success": false,
          "data": null,
          "message": "Error al obtener procesos remotos",
        };
      }
    } catch (e) {
      String errorMessage = "No hay conexión a internet";
      
      if (e.toString().contains("SocketException")) {
        errorMessage = "No hay conexión a internet. Por favor, verifica tu conexión";
      }

      return {
        "success": false,
        "data": null,
        "message": errorMessage,
      };
    }
  }

  Future<Map<String, dynamic>> getDetalleProcesoRemoto(int procesoId) async {
    final url = Uri.parse("$baseUrl/api/procesos/$procesoId");
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 401) {
        final tokenService = await TokenService.getInstance();
        await tokenService.logout();
        return {
          "success": false,
          "data": null,
          "message": "Sesión expirada",
          "sessionExpired": true
        };
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        if (data["success"]) {
          return {
            "success": true,
            "data": data,
            "message": null,
          };
        } else {
          return {
            "success": false,
            "data": null,
            "message": data["message"] ?? "No se encontraron detalles del proceso",
          };
        }
      } else {
        return {
          "success": false,
          "data": null,
          "message": "Error al obtener detalles del proceso",
        };
      }
    } catch (e) {
      String errorMessage = "No hay conexión a internet";
      
      if (e.toString().contains("SocketException")) {
        errorMessage = "No hay conexión a internet. Por favor, verifica tu conexión";
      }

      return {
        "success": false,
        "data": null,
        "message": errorMessage,
      };
    }
  }
}