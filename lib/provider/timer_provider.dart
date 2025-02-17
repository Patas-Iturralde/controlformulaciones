// timer_provider.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerProvider with ChangeNotifier {
  Map<int, Timer> _timers = {};
  Map<int, int> _remainingSeconds = {};
  bool _notificationsEnabled = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  Map<int, int> get remainingSeconds => _remainingSeconds;
  bool get notificationsEnabled => _notificationsEnabled;

  TimerProvider() {
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('timer_notifications') ?? false;
    notifyListeners();
  }

  Future<void> enableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timer_notifications', true);
    _notificationsEnabled = true;
    notifyListeners();
  }

  Future<void> disableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timer_notifications', false);
    _notificationsEnabled = false;
    notifyListeners();
  }

  Future<void> initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        print('Notificación recibida');
      },
    );
    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'timer_channel',
      'Timer Notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _loadNotificationPreferences();
  }

  void startTimer(int index, int minutes, String maquina, String secuencia) {
    _remainingSeconds[index] = minutes * 60;
    _timers[index]?.cancel();

    if (_notificationsEnabled) {
      _showInitNotification(maquina, secuencia, minutes);
    }

    _timers[index] = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds[index]! > 0) {
        _remainingSeconds[index] = _remainingSeconds[index]! - 1;

        if (_notificationsEnabled) {
          if (_remainingSeconds[index] == 300) {
            _showNotification("¡Atención! $maquina",
                "Quedan 5 minutos para finalizar el proceso en secuencia $secuencia\n${_getFormattedDateTime()}");
          }
          if (_remainingSeconds[index] == 60) {
            _showNotification("¡Atención! $maquina",
                "Queda 1 minuto para finalizar el proceso en secuencia $secuencia\n${_getFormattedDateTime()}");
          }
          if (_remainingSeconds[index] == 0) {
            _showNotification("Finalización de Proceso $maquina",
                "El proceso en secuencia $secuencia ha finalizado.\n${_getFormattedDateTime()}");
          }
        }
        notifyListeners();
      } else {
        timer.cancel();
        _timers.remove(index);
        notifyListeners();
      }
    });
  }

  void stopTimer(int index) {
    _timers[index]?.cancel();
    _timers.remove(index);
    _remainingSeconds.remove(index);
    notifyListeners();
  }

  void stopAllTimers() {
    _timers.forEach((_, timer) => timer.cancel());
    _timers.clear();
    _remainingSeconds.clear();
    notifyListeners();
  }

  String _getFormattedDateTime() {
    DateTime now = DateTime.now();
    String formattedTime = "${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}";
    String formattedDate = "${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}";
    return "Fecha: $formattedDate\nHora: $formattedTime";
  }

  Future<void> _showInitNotification(String maquina, String secuencia, int minutes) async {
    if (!_notificationsEnabled) return;

    DateTime endTime = DateTime.now().add(Duration(minutes: minutes));
    String formattedEndTime = "${endTime.hour.toString().padLeft(2,'0')}:${endTime.minute.toString().padLeft(2,'0')}";
    String formattedEndDate = "${endTime.day.toString().padLeft(2,'0')}/${endTime.month.toString().padLeft(2,'0')}/${endTime.year}";

    await _showNotification(
      "Inicio de Proceso $maquina",
      "Se inició el proceso en secuencia $secuencia con duración de $minutes minutos.\nFinalizará el $formattedEndDate a las $formattedEndTime"
    );
  }

  Future<void> _showNotification(String title, String body) async {
    if (!_notificationsEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    try {
      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      print('Error al enviar notificación: $e');
    }
  }

  @override
  void dispose() {
    stopAllTimers();
    super.dispose();
  }
}