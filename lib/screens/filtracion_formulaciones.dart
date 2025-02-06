import 'package:controlformulaciones/screens/control_formulaciones.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class ScanDialog extends StatefulWidget {
  @override
  _ScanDialogState createState() => _ScanDialogState();
}

class _ScanDialogState extends State<ScanDialog> {
  final TextEditingController _codeController = TextEditingController();
  String? _scannedCode;
  bool isScanning = false;
  MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Escanear Código'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Ingresar código manualmente',
                border: OutlineInputBorder(),
              ),
            ),
            if (_scannedCode != null) Text('Código escaneado: $_scannedCode'),
            if (isScanning)
              Container(
                height: 300,
                width: 300,
                child: MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final String code = barcodes.first.rawValue ?? '';
                      setState(() {
                        _scannedCode = code;
                        _codeController.text = code;
                        isScanning = false;
                      });
                      controller.stop();
                    }
                  },
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isScanning = !isScanning;
                      if (!isScanning) {
                        controller.stop();
                      } else {
                        controller.start();
                      }
                    });
                  },
                  icon: Icon(Icons.camera_alt),
                  label: Text(isScanning ? 'Detener' : 'Cámara'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            controller.stop();
            Navigator.pop(context);
          },
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            controller.stop();
            Navigator.pop(context, _scannedCode ?? _codeController.text);
          },
          child: Text('Aceptar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class FiltracionFormulaciones extends StatefulWidget {
  final FormulationItem pesajeItem;
  final List<FormulationItem> bomboItems;

  const FiltracionFormulaciones({
    Key? key,
    required this.pesajeItem,
    required this.bomboItems,
  }) : super(key: key);

  @override
  _FiltracionFormulacionesState createState() =>
      _FiltracionFormulacionesState();
}

class _FiltracionFormulacionesState extends State<FiltracionFormulaciones> {
  late List<FormulationItem> items;
  Map<int, Timer> _timers = {};
  Map<int, int> _remainingSeconds = {};
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();
    items = List.from(widget.bomboItems)
      ..sort((a, b) => a.sec.compareTo(b.sec));
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initNotifications();
  }

  Future<void> _requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
  }

  Future<void> _initNotifications() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) {
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
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      print('Notificaciones inicializadas correctamente');
    } catch (e) {
      print('Error inicializando notificaciones: $e');
    }
  }

  void _startTimer(int index, int minutes) {
    _remainingSeconds[index] = minutes * 60;
    _timers[index]?.cancel();

    // Calcular fecha y hora de finalización
    DateTime now = DateTime.now();
    DateTime endTime = now.add(Duration(minutes: minutes));
    String formattedEndTime =
        "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
    String formattedEndDate =
        "${endTime.day.toString().padLeft(2, '0')}/${endTime.month.toString().padLeft(2, '0')}/${endTime.year}";

    _showNotification("Inicio de Proceso ${widget.pesajeItem.maquina}",
        "Se inició el proceso en secuencia ${items[index].sec} con duración de $minutes minutos.\nFinalizará el $formattedEndDate a las $formattedEndTime");

    _timers[index] = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds[index]! > 0) {
          _remainingSeconds[index] = _remainingSeconds[index]! - 1;

          if (_remainingSeconds[index] == 300) {
            // 5 minutos
            DateTime currentTime = DateTime.now();
            String formattedCurrentTime =
                "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}";
            String formattedCurrentDate =
                "${currentTime.day.toString().padLeft(2, '0')}/${currentTime.month.toString().padLeft(2, '0')}/${currentTime.year}";

            _showNotification("¡Atención! ${widget.pesajeItem.maquina}",
                "Quedan 5 minutos para finalizar el proceso en secuencia ${items[index].sec}\nFecha: $formattedCurrentDate\nHora: $formattedCurrentTime");
          }
          if (_remainingSeconds[index] == 60) {
            // 1 minuto
            DateTime currentTime = DateTime.now();
            String formattedCurrentTime =
                "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}";
            String formattedCurrentDate =
                "${currentTime.day.toString().padLeft(2, '0')}/${currentTime.month.toString().padLeft(2, '0')}/${currentTime.year}";

            _showNotification("¡Atención! ${widget.pesajeItem.maquina}",
                "Queda 1 minuto para finalizar el proceso en secuencia ${items[index].sec}\nFecha: $formattedCurrentDate\nHora: $formattedCurrentTime");
          }
          if (_remainingSeconds[index] == 0) {
            // Finalizar proceso
            DateTime currentTime = DateTime.now();
            String formattedCurrentTime =
                "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}";
            String formattedCurrentDate =
                "${currentTime.day.toString().padLeft(2, '0')}/${currentTime.month.toString().padLeft(2, '0')}/${currentTime.year}";

            _showNotification(
                "Finalización de Proceso ${widget.pesajeItem.maquina}",
                "El proceso en secuencia ${items[index].sec} ha finalizado.\nFecha: $formattedCurrentDate\nHora: $formattedCurrentTime");
          }
        } else {
          timer.cancel();
          _timers.remove(index);
        }
      });
    });
  }

  Future<void> _showNotification(String title, String body) async {
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
      print('Notificación enviada exitosamente');
    } catch (e) {
      print('Error al enviar notificación: $e');
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSecs = seconds % 60;
    return '$minutes:${remainingSecs.toString().padLeft(2, '0')}';
  }

  Future<void> _openCamera(int index) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => ScanDialog(),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        items[index].codigoEscaneado = result;
      });
    }
  }

  void _updateRowStatuses(int currentIndex) {
    setState(() {
      for (int i = 0; i < items.length; i++) {
        if (i < currentIndex) {
          items[i].status =
              items[i].checked ? RowStatus.completed : RowStatus.skipped;
        } else if (i == currentIndex) {
          items[i].status = RowStatus.current;
        } else {
          items[i].status = RowStatus.pending;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pesajeItem.maquina),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OP: ${widget.pesajeItem.nrOp}',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Producto: ${widget.pesajeItem.productoOp}',
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('Control')),
                          DataColumn(label: Text('Sec')),
                          DataColumn(label: Text('Instrucción')),
                          DataColumn(label: Text('Químico')),
                          DataColumn(label: Text('Temp')),
                          DataColumn(label: Text('Tiempo')),
                          DataColumn(label: Text('Scan')),
                        ],
                        rows: items.asMap().entries.map((entry) {
                          int idx = entry.key;
                          FormulationItem item = entry.value;
                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                                switch (item.status) {
                                  case RowStatus.completed:
                                    return Colors.grey[200];
                                  case RowStatus.current:
                                    return Colors.lightBlue[100];
                                  case RowStatus.skipped:
                                    return Colors.orange[100];
                                  case RowStatus.pending:
                                    return null;
                                }
                              },
                            ),
                            cells: [
                              DataCell(Checkbox(
                                value: item.checked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    item.checked = value ?? false;
                                    if (value == true && item.minutos > 0) {
                                      _startTimer(idx, item.minutos);
                                    } else {
                                      _timers[idx]?.cancel();
                                      _timers.remove(idx);
                                      _remainingSeconds.remove(idx);
                                    }
                                    _updateRowStatuses(idx);
                                  });
                                },
                              )),
                              DataCell(Text('${item.sec}')),
                              DataCell(Text(item.operMaquina)),
                              DataCell(Text(item.codProducto)),
                              DataCell(Text('${item.temperatura}°C')),
                              DataCell(
                                Row(
                                  children: [
                                    Text('${item.minutos}min'),
                                    if (_remainingSeconds.containsKey(idx) &&
                                        item.checked)
                                      Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Text(_formatTime(
                                            _remainingSeconds[idx]!)),
                                      ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _openCamera(idx),
                                      icon: Icon(Icons.camera_alt),
                                    ),
                                    if (item.codigoEscaneado != null)
                                      Text(item.codigoEscaneado!,
                                          style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      for (var item in items) {
                        item.checked = false;
                        item.status = RowStatus.pending;
                        item.codigoEscaneado = null;
                      }
                      _timers.forEach((_, timer) => timer.cancel());
                      _timers.clear();
                      _remainingSeconds.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Reiniciar\nProceso',
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    // Implementar lógica para fin de proceso
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Fin\nProceso',
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    // Implementar lógica para trabajo adicional
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Trabajo\nAdicional',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timers.forEach((_, timer) => timer.cancel());
    super.dispose();
  }
}
