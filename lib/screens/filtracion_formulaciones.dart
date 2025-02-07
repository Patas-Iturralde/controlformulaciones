import 'package:controlformulaciones/screens/control_formulaciones.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:controlformulaciones/provider/timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

class TrabajoAdicionalDialog extends StatefulWidget {
  final double prevSecuencia;

  TrabajoAdicionalDialog({required this.prevSecuencia});

  @override
  _TrabajoAdicionalDialogState createState() => _TrabajoAdicionalDialogState();
}

class _TrabajoAdicionalDialogState extends State<TrabajoAdicionalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _instruccionController = TextEditingController();
  final _productoController = TextEditingController();
  final _temperaturaController = TextEditingController();
  final _tiempoController = TextEditingController();
  final _ctdExplosionController = TextEditingController();
  final _observacionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Agregar Paso Adicional'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Secuencia: ${widget.prevSecuencia + 0.1}'),
              TextFormField(
                controller: _instruccionController,
                decoration: InputDecoration(labelText: 'Instrucción'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _productoController,
                decoration: InputDecoration(labelText: 'Producto'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _temperaturaController,
                decoration: InputDecoration(labelText: 'Temperatura'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _tiempoController,
                decoration: InputDecoration(labelText: 'Tiempo (minutos)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _ctdExplosionController,
                decoration: InputDecoration(labelText: 'Cantidad Explosión'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _observacionController,
                decoration: InputDecoration(labelText: 'Observación'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'secuencia': widget.prevSecuencia + 0.1,
                'instruccion': _instruccionController.text,
                'producto': _productoController.text,
                'temperatura': double.parse(_temperaturaController.text),
                'tiempo': int.parse(_tiempoController.text),
                'ctdExplosion': _ctdExplosionController.text.isEmpty
                    ? null
                    : double.parse(_ctdExplosionController.text),
                'observacion': _observacionController.text.isEmpty
                    ? null
                    : _observacionController.text,
              });
            }
          },
          child: Text('Agregar'),
        ),
      ],
    );
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

  @override
  void initState() {
    super.initState();
    // Initialize items from bomboItems
    items = List.from(widget.bomboItems)
      ..sort((a, b) => a.sec.compareTo(b.sec));
    context.read<TimerProvider>().initNotifications();
    
    // Load saved items
    _loadItems();
  }

  // Method to save items to SharedPreferences
  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString('items_${widget.pesajeItem.nrOp}', encodedData);
  }

  // Method to load items from SharedPreferences
  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('items_${widget.pesajeItem.nrOp}');
    if (encodedData != null) {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      setState(() {
        items = decodedData.map((item) => FormulationItem.fromJson(item)).toList();
      });
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
        // Save changes
        _saveItems();
      });
    }
  }

  Future<void> _showObservacionDialog(int index) async {
    final TextEditingController _observacionController =
        TextEditingController();
    _observacionController.text = items[index].observacion ?? '';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Observación'),
          content: TextField(
            controller: _observacionController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  items[index].observacion = _observacionController.text;
                  // Save changes
                  _saveItems();
                });
                Navigator.pop(context);
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCantidadExplosionDialog(int index) async {
    final TextEditingController _cantidadController = TextEditingController();
    _cantidadController.text = items[index].ctdExplosion?.toString() ?? '';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cantidad Explosión'),
          content: TextField(
            controller: _cantidadController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  items[index].ctdExplosion =
                      double.tryParse(_cantidadController.text);
                  // Save changes
                  _saveItems();
                });
                Navigator.pop(context);
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTrabajoAdicionalDialog(FormulationItem prevItem) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) => TrabajoAdicionalDialog(
        prevSecuencia: prevItem.sec.toDouble(),
      ),
    );

    if (result != null) {
      setState(() {
        // Crear nuevo FormulationItem con los datos del diálogo
        final newItem = FormulationItem(
          idPesagemItem: 0,
          nrOp: prevItem.nrOp,
          codProducto: prevItem.codProducto,
          productoOp: prevItem.productoOp,
          maquina: prevItem.maquina,
          sec: double.parse('${prevItem.sec}.1').round(), // Esto asegura que sea 1.1, 2.1, etc.
          operMaquina: result['instruccion'],
          temperatura: result['temperatura'],
          minutos: result['tiempo'],
          situacion: prevItem.situacion,
          fechaApertura: prevItem.fechaApertura,
          productoPesaje: result['producto'],
          ctdExplosion: result['ctdExplosion'],
          observacion: result['observacion'],
        );

        // Encontrar el índice del item previo
        final prevIndex = items.indexWhere((item) => item.sec == prevItem.sec);
        
        // Insertar el nuevo item justo después del item previo
        items.insert(prevIndex + 1, newItem);
        
        // Reordenar la lista por secuencia para mantener el orden correcto
        items.sort((a, b) {
          // Convertir las secuencias a números decimales para comparar correctamente
          double seqA = double.parse(a.sec.toString().contains('.') ? 
            a.sec.toString() : '${a.sec}.0');
          double seqB = double.parse(b.sec.toString().contains('.') ? 
            b.sec.toString() : '${b.sec}.0');
          return seqA.compareTo(seqB);
        });

        // Guardar los cambios
        _saveItems();
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
      // Save changes
      _saveItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.pesajeItem.maquina),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, items);
              },
            ),
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
                        Text('Orden de Produción: ${widget.pesajeItem.nrOp}',
                            style: TextStyle(fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Producto: ${widget.pesajeItem.productoOp}',
                            style: TextStyle(fontSize: 16)),
                        Text(
                            'Código producto: ${widget.pesajeItem.codProducto}',
                            style: TextStyle(fontSize: 16)),
                        Text('Número de pesaje: ${widget.pesajeItem.nrOp}',
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
                              DataColumn(label: Text('Producto')),
                              DataColumn(label: Text('Temp')),
                              DataColumn(label: Text('Tiempo')),
                              DataColumn(label: Text('Ctd Explosion')),
                              DataColumn(label: Text('Observación')),
                              DataColumn(label: Text('Scan')),
                            ],
                            rows: items.asMap().entries.map((entry) {
                              int idx = entry.key;
                              FormulationItem item = entry.value;
                              return DataRow(
                                color:
                                    MaterialStateProperty.resolveWith<Color?>(
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
                                          timerProvider.startTimer(
                                            idx,
                                            item.minutos,
                                            widget.pesajeItem.maquina,
                                            item.sec.toString(),
                                          );
                                        } else {
                                          timerProvider.stopTimer(idx);
                                        }
                                        _updateRowStatuses(idx);
                                        // Save changes
                                        _saveItems();
                                      });
                                    },
                                  )),
                                  DataCell(Text('${item.sec}')),
                                  DataCell(
                                    GestureDetector(
                                      onDoubleTap: () {
                                        final instruccion =
                                            item.operMaquina.toUpperCase();
                                        if ([
                                          'ADICIONAR AGUA',
                                          'CONTROLAR PH',
                                          'CONTROL HUMECTACION',
                                          'CONTROL ATRAVESADO',
                                          'CONTROL AGOTAMIENTO'
                                        ].contains(instruccion)) {
                                          _showObservacionDialog(idx);
                                        } else if ([
                                          'AGREGAR PQ TAMBOR',
                                          'AÑADIR TINTA'
                                        ].contains(instruccion)) {
                                          _showCantidadExplosionDialog(idx);
                                        }
                                      },
                                      child: Text(item.operMaquina),
                                    ),
                                  ),
                                  DataCell(Text(item.productoPesaje ?? '')),
                                  DataCell(Text('${item.temperatura}°C')),
                                  DataCell(
                                    Row(
                                      children: [
                                        Text('${item.minutos}min'),
                                        if (timerProvider.remainingSeconds
                                                .containsKey(idx) &&
                                            item.checked)
                                          Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Text(_formatTime(
                                                timerProvider
                                                    .remainingSeconds[idx]!)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(
                                      item.ctdExplosion?.toString() ?? '')),
                                  DataCell(Text(item.observacion ?? '')),
                                  DataCell(
                                    [
                                      'AGREGAR PQ TAMBOR',
                                      'AÑADIR TINTA'
                                    ].contains(item.operMaquina.toUpperCase())
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: () =>
                                                    _openCamera(idx),
                                                icon: Icon(Icons.camera_alt),
                                              ),
                                              if (item.codigoEscaneado != null)
                                                Text(item.codigoEscaneado!,
                                                    style: TextStyle(
                                                        fontSize: 12)),
                                            ],
                                          )
                                        : Container(),
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
                          timerProvider.stopAllTimers();
                          // Save changes after reset
                          _saveItems();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        'Fin\nProceso',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        if (items.isEmpty) return;

                        // Mostrar diálogo para seleccionar después de qué secuencia agregar
                        final selectedItem = await showDialog<FormulationItem>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Seleccionar Secuencia'),
                              content: Container(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return ListTile(
                                      title: Text('Secuencia ${item.sec}'),
                                      subtitle: Text(item.operMaquina),
                                      onTap: () => Navigator.pop(context, item),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );

                        if (selectedItem != null) {
                          await _showTrabajoAdicionalDialog(selectedItem);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      },
    );
  }
}