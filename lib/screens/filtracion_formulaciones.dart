// filtracion_formulaciones.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:controlformulaciones/provider/timer_provider.dart';
import 'package:controlformulaciones/data/db_helper.dart';
import 'package:controlformulaciones/screens/control_formulaciones.dart';
import 'package:controlformulaciones/services/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:intl/intl.dart';

// Widget del Scanner
class ScanDialog extends StatefulWidget {
  @override
  _ScanDialogState createState() => _ScanDialogState();
}

//Pantalla de dialogo para codigo de barras o QR
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

// Widget de Trabajo Adicional
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
  final _temperaturaController = TextEditingController();
  final _tiempoController = TextEditingController();
  final _ctdExplosionController = TextEditingController();
  final _observacionController = TextEditingController();
  final _operacionController = TextEditingController();
  final _productoController = TextEditingController();

  Map<String, dynamic>? _selectedOperacion;
  Map<String, dynamic>? _selectedProducto;
  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> operaciones = [];
  bool isLoadingProductos = true;
  bool isLoadingOperaciones = true;

  @override
  void initState() {
    super.initState();
    _loadProductos();
    _loadOperaciones();
  }

  Future<void> _loadProductos() async {
    try {
      final response = await widget.apiService.getProductosQuimicos();
      if (response['success']) {
        setState(() {
          productos = List<Map<String, dynamic>>.from(response['data']);
          isLoadingProductos = false;
        });
      }
    } catch (e) {
      print('Error cargando productos: $e');
      setState(() => isLoadingProductos = false);
    }
  }

  Future<void> _loadOperaciones() async {
    try {
      final response = await widget.apiService.getOperaciones();
      if (response['success']) {
        setState(() {
          operaciones = List<Map<String, dynamic>>.from(response['data']);
          isLoadingOperaciones = false;
        });
      }
    } catch (e) {
      print('Error cargando operaciones: $e');
      setState(() => isLoadingOperaciones = false);
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
              if (isLoadingOperaciones)
                CircularProgressIndicator()
              else
                Autocomplete<Map<String, dynamic>>(
                  initialValue: TextEditingValue(
                      text: _selectedOperacion?['nm_operacao_maquina'] ?? ''),
                  displayStringForOption: (Map<String, dynamic> option) =>
                      option['nm_operacao_maquina'],
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return operaciones;
                    }
                    return operaciones.where((operacion) {
                      return operacion['nm_operacao_maquina']
                          .toString()
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (Map<String, dynamic> selection) {
                    setState(() {
                      _selectedOperacion = selection;
                      _operacionController.text =
                          selection['nm_operacao_maquina'];
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Buscar Operación *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => _selectedOperacion == null
                          ? 'Seleccione una operación'
                          : null,
                    );
                  },
                ),
              SizedBox(height: 16),
              if (isLoadingProductos)
                CircularProgressIndicator()
              else
                Autocomplete<Map<String, dynamic>>(
                  initialValue: TextEditingValue(
                      text: _selectedProducto?['nombre'] ?? ''),
                  displayStringForOption: (Map<String, dynamic> option) =>
                      '${option['codigo']} - ${option['nombre']}',
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return productos;
                    }
                    return productos.where((producto) {
                      final searchText = textEditingValue.text.toLowerCase();
                      return producto['nombre']
                              .toString()
                              .toLowerCase()
                              .contains(searchText) ||
                          producto['codigo']
                              .toString()
                              .toLowerCase()
                              .contains(searchText);
                    });
                  },
                  onSelected: (Map<String, dynamic> selection) {
                    setState(() {
                      _selectedProducto = selection;
                      _productoController.text = selection['nombre'];
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Buscar Producto',
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
              // TextFormField(
              //   controller: _temperaturaController,
              //   decoration: InputDecoration(
              //     labelText: 'Temperatura',
              //     border: OutlineInputBorder(),
              //   ),
              //   keyboardType: TextInputType.number,
              // ),
              // SizedBox(height: 16),
              // TextFormField(
              //   controller: _tiempoController,
              //   decoration: InputDecoration(
              //     labelText: 'Tiempo (minutos)',
              //     border: OutlineInputBorder(),
              //   ),
              //   keyboardType: TextInputType.number,
              // ),
              SizedBox(height: 16),
              TextFormField(
                controller: _ctdExplosionController,
                decoration: InputDecoration(
                  labelText: 'Cantidad Explosión',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _observacionController,
                decoration: InputDecoration(
                  labelText: 'Observación',
                  border: OutlineInputBorder(),
                ),
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
                'instruccion': _selectedOperacion!['nm_operacao_maquina'],
                'producto': _selectedProducto?['nombre'],
                'codigoProducto': _selectedProducto?['codigo'],
                'temperatura': _temperaturaController.text.isNotEmpty
                    ? double.parse(_temperaturaController.text)
                    : 0.0,
                'tiempo': _tiempoController.text.isNotEmpty
                    ? int.parse(_tiempoController.text)
                    : 0,
                'ctdExplosion': _ctdExplosionController.text.isNotEmpty
                    ? double.parse(_ctdExplosionController.text)
                    : null,
                'observacion': _observacionController.text.isNotEmpty
                    ? _observacionController.text
                    : null,
              });
            }
          },
          child: Text('Agregar'),
        ),
      ],
    );
  }
}

// Pantalla Principal de Filtración
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
  final ApiService _apiService = ApiService();
  final DBHelper _dbHelper = DBHelper();
  late List<FormulationItem> items;
  Map<int, DateTime> _startTimes = {};
  Map<int, DateTime> _endTimes = {};

  @override
  void initState() {
    super.initState();
    items = List.from(widget.bomboItems)
      ..sort((a, b) => a.sec.compareTo(b.sec));
    context.read<TimerProvider>().initNotifications();
  }

  // Función auxiliar para determinar si el checkbox debe estar deshabilitado
  bool _isCheckboxDisabled(int index) {
    final item = items[index];

    // Si ya está completada y tiene hora de fin, no se puede desmarcar
    if (item.checked && _endTimes.containsKey(index)) {
      return true;
    }

    // Verificar si hay secuencias posteriores que se hayan marcado
    bool haySecuenciaPosteriorMarcada = false;
    for (int i = index + 1; i < items.length; i++) {
      if (items[i].checked) {
        haySecuenciaPosteriorMarcada = true;
        break;
      }
    }

    // Si hay una secuencia posterior marcada, esta secuencia queda bloqueada
    if (haySecuenciaPosteriorMarcada) {
      return true;
    }

    return false;
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
          codProducto: result['codigoProducto'] ?? '',
          productoOp: prevItem.productoOp,
          maquina: prevItem.maquina,
          sec: double.parse('${prevItem.sec}.1').round(),
          operMaquina: result['instruccion'],
          temperatura: result['temperatura'],
          minutos: result['tiempo'],
          situacion: prevItem.situacion,
          fechaApertura: prevItem.fechaApertura,
          productoPesaje: result['producto'] ?? '',
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

  Future<pw.Font> _loadFont() async {
    final fontData = await rootBundle
        .load("packages/pdf/src/fonts/open_sans/OpenSans-Regular.ttf");
    return pw.Font.ttf(fontData.buffer.asByteData());
  }

  Future<pw.Document> _generarPDF() async {
    // Filtrar solo las secuencias iniciadas
    final iniciadas = items
        .asMap()
        .entries
        .where((entry) => _startTimes.containsKey(entry.key))
        .toList();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            child: pw.Column(
              children: [
                pw.Container(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Usuario Responsable',
                              style: const pw.TextStyle(fontSize: 14)),
                          pw.Text(
                              'OP: ${widget.pesajeItem.nrOp} - Maq.: ${widget.pesajeItem.maquina}',
                              style: const pw.TextStyle(fontSize: 14)),
                        ],
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text('Producto: ${widget.pesajeItem.productoOp}',
                          style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('Fecha: ${widget.pesajeItem.fechaApertura}',
                          style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1), // Secuencia
                    1: const pw.FlexColumnWidth(2), // Instrucción
                    2: const pw.FlexColumnWidth(2), // Producto
                    3: const pw.FlexColumnWidth(1.5), // Ctd Explosión
                    4: const pw.FlexColumnWidth(2), // Observación
                    5: const pw.FlexColumnWidth(1), // Inicio
                    6: const pw.FlexColumnWidth(1), // Fin
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        'Secuencia',
                        'Instrucción',
                        'Producto',
                        'Cantidad/Control',
                        'Observación',
                        'Hora Inicio',
                        'Hora Fin',
                      ]
                          .map((text) => pw.Container(
                                padding: const pw.EdgeInsets.all(5),
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  text,
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ))
                          .toList(),
                    ),
                    ...iniciadas.map((entry) {
                      int idx = entry.key;
                      FormulationItem item = entry.value;
                      String formatDateTime(DateTime? dateTime) {
                        if (dateTime == null) return '';
                        return DateFormat('HH:mm').format(dateTime);
                      }

                      return pw.TableRow(
                        children: [
                          _buildPdfCell(item.sec.toString()),
                          _buildPdfCell(item.operMaquina),
                          _buildPdfCell(item.productoPesaje ?? ''),
                          _buildPdfCell(item.ctdExplosion?.toString() ?? ''),
                          _buildPdfCell(item.observacion ?? ''),
                          _buildPdfCell(formatDateTime(_startTimes[idx])),
                          _buildPdfCell(formatDateTime(_endTimes[idx])),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.Spacer(),
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  margin: const pw.EdgeInsets.only(top: 10),
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.5),
                    ),
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    // child: pw.Text(
                    //   'Tiempo Total Fórmula: ${_calcularTiempoTotal()}',
                    //   style: const pw.TextStyle(fontSize: 10),
                    // ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  String _calcularTiempoTotal() {
    int tiempoTotal = 0;
    for (var item in items) {
      tiempoTotal += item.minutos;
    }
    return tiempoTotal.toString();
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
                        Text(
                            'Número de pesaje: ${widget.pesajeItem.numeroPesaje}',
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
                                    onChanged: _isCheckboxDisabled(idx)
                                        ? null
                                        : (bool? value) async {
                                            // Si estamos intentando marcar una nueva secuencia
                                            if (value == true) {
                                              // Buscar si hay una secuencia anterior con temporizador activo
                                              int currentIndex = idx;
                                              int previousActiveIndex = -1;

                                              for (int i = 0;
                                                  i < items.length;
                                                  i++) {
                                                if (i != currentIndex &&
                                                    items[i].checked &&
                                                    timerProvider
                                                        .remainingSeconds
                                                        .containsKey(i) &&
                                                    !_endTimes.containsKey(i)) {
                                                  previousActiveIndex = i;
                                                  break;
                                                }
                                              }

                                              // Si encontramos una secuencia activa anterior
                                              if (previousActiveIndex != -1) {
                                                // Preguntar si desea finalizar la secuencia anterior
                                                bool? finalizarAnterior =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text(
                                                          'Secuencia Activa'),
                                                      content: Text(
                                                          '¿Desea finalizar la secuencia ${items[previousActiveIndex].sec} antes de iniciar la nueva?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  false),
                                                          child:
                                                              Text('Cancelar'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  true),
                                                          child: Text(
                                                              'Finalizar y Continuar'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );

                                                // Si el usuario canceló, no hacemos nada
                                                if (finalizarAnterior == null ||
                                                    !finalizarAnterior) {
                                                  return;
                                                }

                                                // Finalizar la secuencia anterior
                                                setState(() {
                                                  _endTimes[
                                                          previousActiveIndex] =
                                                      DateTime.now();
                                                  timerProvider.stopTimer(
                                                      previousActiveIndex);
                                                });
                                              }

                                              // Iniciar la nueva secuencia
                                              setState(() {
                                                item.checked = true;
                                                _startTimes[idx] =
                                                    DateTime.now();
                                                if (item.minutos > 0) {
                                                  timerProvider.startTimer(
                                                    idx,
                                                    item.minutos,
                                                    widget.pesajeItem.maquina,
                                                    item.sec.toString(),
                                                  );
                                                }
                                                _updateRowStatuses(idx);
                                              });
                                            }
                                            // Si estamos intentando desmarcar una secuencia
                                            else if (!_endTimes
                                                .containsKey(idx)) {
                                              // Solo permitir desmarcar si no está finalizada
                                              setState(() {
                                                item.checked = false;
                                                _endTimes[idx] = DateTime.now();
                                                timerProvider.stopTimer(idx);
                                                _updateRowStatuses(idx);
                                              });
                                            }
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
                          // Restaurar la lista original de items
                          items = List.from(widget.bomboItems)
                            ..sort((a, b) => a.sec.compareTo(b.sec));
                          // Reiniciar el estado de cada item
                          for (var item in items) {
                            item.checked = false;
                            item.status = RowStatus.pending;
                            item.codigoEscaneado = null;
                          }
                          timerProvider.stopAllTimers();
                          _startTimes.clear();
                          _endTimes.clear();
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
                      onPressed: () async {
                        try {
                          // Obtener directorio para guardar el PDF
                          final directory =
                              await getApplicationDocumentsDirectory();
                          final String pdfPath =
                              '${directory.path}/reporte_${widget.pesajeItem.nrOp}_${DateTime.now().millisecondsSinceEpoch}.pdf';

                          // Preparar datos del proceso
                          Map<String, dynamic> proceso = {
                            'nrOp': widget.pesajeItem.nrOp,
                            'numeroPesaje': widget.pesajeItem.numeroPesaje,
                            'maquina': widget.pesajeItem.maquina,
                            'producto': widget.pesajeItem.productoOp,
                            'codProducto': widget.pesajeItem.codProducto,
                            'fecha_proceso': widget.pesajeItem.fechaApertura,
                            'fecha_guardado': DateTime.now().toIso8601String(),
                            'pdfPath': pdfPath,
                            'situacion': widget.pesajeItem.situacion,
                          };

                          // Guardar en SQLite y obtener ID
                          int procesoId =
                              await _dbHelper.insertProceso(proceso);

                          // Lista para secuencias iniciadas que se sincronizarán
                          List<Map<String, dynamic>> secuencias = [];

                          // Procesar cada secuencia
                          for (var i = 0; i < items.length; i++) {
                            var item = items[i];

                            // Preparar datos de la secuencia
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
                              'hora_inicio': _startTimes[i]?.toIso8601String(),
                              'hora_fin': _endTimes[i]?.toIso8601String(),
                            };

                            // Guardar en SQLite
                            await _dbHelper.insertSecuencia(secuencia);

                            // Si la secuencia fue iniciada, agregarla para sincronización
                            if (_startTimes.containsKey(i)) {
                              secuencias.add({
                                ...secuencia,
                                'hora_inicio':
                                    _startTimes[i]?.toIso8601String(),
                                'hora_fin': _endTimes[i]?.toIso8601String(),
                              });
                            }
                          }

                          // Intentar sincronizar con el servidor
                          final syncResult =
                              await _apiService.sincronizarPesaje(
                            proceso: proceso,
                            secuencias: secuencias,
                          );

                          // Manejar resultado de sincronización
                          if (!syncResult['success']) {
                            if (syncResult['sessionExpired'] == true) {
                              // Si la sesión expiró, mostrar mensaje y redirigir al login
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Su sesión ha expirado. Por favor, inicie sesión nuevamente.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              // Aquí puedes agregar la navegación al login si es necesario
                              return;
                            } else {
                              // Si falló por otra razón, mostrar advertencia pero continuar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Advertencia: ${syncResult['message']}. Los datos se sincronizarán más tarde.'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 4),
                                ),
                              );
                            }
                          }

                          // Generar y guardar PDF
                          final pdf = await _generarPDF();
                          final File file = File(pdfPath);
                          await file.writeAsBytes(await pdf.save());

                          // Mostrar mensaje de éxito
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(syncResult['success']
                                  ? 'Proceso guardado y sincronizado correctamente'
                                  : 'Proceso guardado localmente'),
                              backgroundColor: syncResult['success']
                                  ? Colors.green
                                  : Colors.blue,
                              duration: Duration(seconds: 3),
                            ),
                          );

                          // Volver a la pantalla anterior
                          Navigator.pop(context, items);
                        } catch (e) {
                          print('Error al guardar proceso: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Error al guardar el proceso: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
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

                          final selectedItem =
                              await showDialog<FormulationItem>(
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
                                        onTap: () =>
                                            Navigator.pop(context, item),
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
                          ;
                          style:
                          ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          );
                        },
                        child: Text(
                          'Trabajo\nAdicional',
                          textAlign: TextAlign.center,
                        )),
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

// Puedes agregar esta extensión al final del archivo para formatear fechas
extension DateTimeExtension on DateTime {
  String toFormattedString() {
    return DateFormat('dd/MM/yyyy HH:mm').format(this);
  }
}
