import 'package:flutter/material.dart';
import 'package:controlformulaciones/screens/control_formulaciones.dart';
import 'package:controlformulaciones/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      // Solicitar permiso primero
      final status = await Permission.notification.request();
      if (status.isGranted) {
        const androidInit =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: androidInit);

        await flutterLocalNotificationsPlugin.initialize(
          initSettings,
          onDidReceiveNotificationResponse:
              (NotificationResponse notificationResponse) {
            print('Notificación recibida');
          },
        );

        // Crear el canal de notificaciones
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'test_channel',
          'Test Notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        print('Notificaciones inicializadas correctamente');
      } else {
        print('Permiso de notificaciones denegado');
      }
    } catch (e) {
      print('Error inicializando notificaciones: $e');
    }
  }

  void _startTestTimer() {
    // Cambiamos a 20 segundos para pruebas
    final totalSeconds = 20;
    _remainingSeconds = totalSeconds;

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          print('Tiempo restante: $_remainingSeconds segundos');

          if (_remainingSeconds == 10) {
            // Notificar a los 10 segundos
            _showNotification("Prueba de Notificación",
                "¡Quedan 10 segundos en el temporizador de prueba!");
            print('Enviando notificación...');
          }
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,

      icon: '@mipmap/ic_launcher',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        notificationDetails,
      );
      print('Notificación enviada exitosamente');
    } catch (e) {
      print('Error al enviar notificación: $e');
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (response['success']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ControlFormulaciones(
              userData: response['user'],
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Error al iniciar sesión';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(230, 235, 237, 1),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Image.asset('assets/images/logo_login.png'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Iniciar Sesión',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Ingresar'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startTestTimer,
                child: Text('Probar Notificación (20s)'),
              ),
              if (_remainingSeconds > 0)
                Text(
                  'Tiempo restante: ${(_remainingSeconds / 60).floor()}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
