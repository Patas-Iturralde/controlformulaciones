// FiltracionFormulaciones.dart
import 'package:controlformulaciones/screens/control_formulaciones.dart';
import 'package:controlformulaciones/services/api_service.dart';
import 'package:controlformulaciones/db_helper.dart';
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

// Importar paquetes para PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// -------------------------
/// Diálogo del Scanner
/// -------------------------
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

/// -------------------------
/// Diálogo de Trabajo Adicional
/// -------------------------
class TrabajoAdicionalDialog extends StatefulWidget {
  final double prevSecuencia;
  final ApiService apiService;

  TrabajoAdicionalDialog({
    required this.prevSecuencia,
    required this.apiService,
  });

  @override
  _TrabajoAdicionalDialogState createState() => _TrabajoAdicionalDialogState();
}

class _TrabajoAdicionalDialogState extends State<TrabajoAdicionalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _instruccionController = TextEditingController();
  String? _selectedProducto;
  final _temperaturaController = TextEditingController();
  final _tiempoController = TextEditingController();
  final _ctdExplosionController = TextEditingController();
  final _observacionController = TextEditingController();

  List<Map<String, dynamic>> productos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    try {
      final response = await widget.apiService.getProductosQuimicos();
      if (response['success']) {
        setState(() {
          productos = List<Map<String, dynamic>>.from(response['data']);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando productos: $e');
      setState(() => isLoading = false);
    }
  }

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
              if (isLoading)
                CircularProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  value: _selectedProducto,
                  decoration: InputDecoration(labelText: 'Producto'),
                  items: productos.map((Map<String, dynamic> producto) {
                    return DropdownMenuItem<String>(
                      value: producto['codigo'] as String,
                      child: Text(producto['nombre'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProducto = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Campo requerido' : null,
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
              final selectedProductoData =
                  productos.firstWhere((p) => p['codigo'] == _selectedProducto);

              Navigator.pop(context, {
                'secuencia': widget.prevSecuencia + 0.1,
                'instruccion': _instruccionController.text,
                'producto': selectedProductoData['nombre'],
                'codigoProducto': _selectedProducto,
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

/// -------------------------
/// Pantalla Principal de Filtración
/// -------------------------
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
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    items = List.from(widget.bomboItems)
      ..sort((a, b) => a.sec.compareTo(b.sec));
    context.read<TimerProvider>().initNotifications();
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

  Future<void> _showTrabajoAdicionalDialog(FormulationItem prevItem) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) => TrabajoAdicionalDialog(
        prevSecuencia: prevItem.sec.toDouble(),
        apiService: _apiService,
      ),
    );

    if (result != null) {
      setState(() {
        final newItem = FormulationItem(
          idPesagemItem: 0,
          nrOp: prevItem.nrOp,
          numeroPesaje: prevItem.numeroPesaje,
          codProducto: result['codigoProducto'],
          productoOp: prevItem.productoOp,
          maquina: prevItem.maquina,
          sec: double.parse('${prevItem.sec}.1').round(),
          operMaquina: result['instruccion'],
          temperatura: result['temperatura'],
          minutos: result['tiempo'],
          situacion: prevItem.situacion,
          fechaApertura: prevItem.fechaApertura,
          productoPesaje: result['producto'],
          ctdExplosion: result['ctdExplosion'],
          observacion: result['observacion'],
        );

        final prevIndex = items.indexWhere((item) => item.sec == prevItem.sec);
        items.insert(prevIndex + 1, newItem);

        items.sort((a, b) {
          double seqA = double.parse(
              a.sec.toString().contains('.') ? a.sec.toString() : '${a.sec}.0');
          double seqB = double.parse(
              b.sec.toString().contains('.') ? b.sec.toString() : '${b.sec}.0');
          return seqA.compareTo(seqB);
        });
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
                        Text('OP: ${widget.pesajeItem.nrOp}',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Producto: ${widget.pesajeItem.productoOp}',
                            style: TextStyle(fontSize: 16)),
                        Text(
                            'Código producto: ${widget.pesajeItem.codProducto}',
                            style: TextStyle(fontSize: 16)),
                        Text('Número de pesaje: ${widget.pesajeItem.numeroPesaje}',
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
                    // Botón Fin Proceso: Guarda en SQLite, genera PDF y limpia la base de datos.
                    ElevatedButton(
                      onPressed: () async {
                        final dbHelper = DBHelper();

                        // Construir el registro del proceso
                        Map<String, dynamic> proceso = {
                          'nrOp': widget.pesajeItem.nrOp,
                          'maquina': widget.pesajeItem.maquina,
                          'producto': widget.pesajeItem.productoOp,
                          'fecha_guardado': DateTime.now().toIso8601String(),
                          'fecha_proceso': widget.pesajeItem.fechaApertura,
                        };

                        // Insertar el proceso y obtener su ID
                        int procesoId = await dbHelper.insertProceso(proceso);
                        print("Proceso insertado con ID: $procesoId");

                        // Insertar cada secuencia asociada al proceso
                        for (var item in items) {
                          Map<String, dynamic> secuencia = {
                            'proceso_id': procesoId,
                            'secuencia': item.sec,
                            'instruccion': item.operMaquina,
                            'producto': item.productoPesaje,
                            'temperatura': item.temperatura,
                            'tiempo': item.minutos,
                            'ctd_explosion': item.ctdExplosion,
                            'observacion': item.observacion,
                            'codigo_escaneado': item.codigoEscaneado,
                          };
                          await dbHelper.insertSecuencia(secuencia);
                          print("Secuencia insertada: ${secuencia.toString()}");
                        }

                        // Recuperar las secuencias asociadas al proceso
                        List<Map<String, dynamic>> secuencias =
                            await dbHelper.getSecuencias(procesoId);
                        print("Secuencias recuperadas: ${secuencias.length}");

                        // Generar el documento PDF
                        final pdf = pw.Document();
                        pdf.addPage(
                          pw.MultiPage(
                            build: (pw.Context context) {
                              return [
                                pw.Header(
                                  level: 0,
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text('Detalle de Proceso',
                                          style: pw.TextStyle(
                                              fontSize: 24,
                                              fontWeight: pw.FontWeight.bold)),
                                      pw.Divider(),
                                      pw.Text('Proceso ID: $procesoId',
                                          style: pw.TextStyle(fontSize: 16)),
                                      pw.Text('OP: ${widget.pesajeItem.nrOp}',
                                          style: pw.TextStyle(fontSize: 16)),
                                      pw.Text(
                                          'Máquina: ${widget.pesajeItem.maquina}',
                                          style: pw.TextStyle(fontSize: 16)),
                                      pw.Text(
                                          'Producto: ${widget.pesajeItem.productoOp}',
                                          style: pw.TextStyle(fontSize: 16)),
                                      pw.Text(
                                          'Fecha Proceso: ${widget.pesajeItem.fechaApertura}',
                                          style: pw.TextStyle(fontSize: 16)),
                                      pw.Text(
                                          'Fecha Guardado: ${DateTime.now().toIso8601String()}',
                                          style: pw.TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ),
                                pw.SizedBox(height: 20),
                                pw.TableHelper.fromTextArray(
                                  context: context,
                                  border: pw.TableBorder.all(
                                      color: PdfColors.black),
                                  headerStyle: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                  headerDecoration: pw.BoxDecoration(
                                      color: PdfColors.grey300),
                                  cellStyle: pw.TextStyle(fontSize: 10),
                                  cellAlignments: {
                                    0: pw.Alignment.centerLeft,
                                    1: pw.Alignment.centerLeft,
                                    2: pw.Alignment.centerLeft,
                                    3: pw.Alignment.center,
                                    4: pw.Alignment.center,
                                    5: pw.Alignment.center,
                                    6: pw.Alignment.centerLeft,
                                    7: pw.Alignment.centerLeft,
                                  },
                                  headers: [
                                    'Secuencia',
                                    'Instrucción',
                                    'Producto',
                                    'Temperatura',
                                    'Tiempo',
                                    'Ctd Explosión',
                                    'Observación',
                                    'Código Escaneado'
                                  ],
                                  data: items
                                      .map<List<String>>((item) => [
                                            item.sec.toString(),
                                            item.operMaquina ?? '',
                                            item.productoPesaje ?? '',
                                            '${item.temperatura}°C',
                                            '${item.minutos} min',
                                            item.ctdExplosion?.toString() ?? '',
                                            item.observacion ?? '',
                                            item.codigoEscaneado ?? '',
                                          ])
                                      .toList(),
                                ),
                              ];
                            },
                            footer: (pw.Context context) {
                              return pw.Container(
                                alignment: pw.Alignment.centerRight,
                                margin: const pw.EdgeInsets.only(top: 10),
                                child: pw.Text(
                                  'Página ${context.pageNumber} de ${context.pagesCount}',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        );

                        

                        // Mostrar la vista previa y permitir la impresión/guardado del PDF
                        await Printing.layoutPdf(
                          onLayout: (PdfPageFormat format) async => pdf.save(),
                        );

                        // Limpiar los datos de las tablas
                        await dbHelper.deleteAllData();
                        print("Datos limpiados de la base de datos");

                        // Reiniciar la UI (opcional)
                        setState(() {
                          for (var item in items) {
                            item.checked = false;
                            item.status = RowStatus.pending;
                            item.codigoEscaneado = null;
                          }
                          timerProvider.stopAllTimers();
                        });

                        // Notificar al usuario
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Proceso guardado, PDF generado y datos limpiados.',
                            ),
                          ),
                        );
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
