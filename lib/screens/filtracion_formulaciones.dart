import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanDialog extends StatefulWidget {
  @override
  _ScanDialogState createState() => _ScanDialogState();
}

class _ScanDialogState extends State<ScanDialog> {
  final TextEditingController _codeController = TextEditingController();
  String? _scannedCode;
  bool isScanning = false;
  MobileScannerController controller = MobileScannerController();

  Future<void> _scanFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _scannedCode = "Código de imagen";
        });
      }
    } catch (e) {
      print("Error scanning from gallery: $e");
    }
  }

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
            SizedBox(height: 20),
            if (_scannedCode != null)
              Text('Código escaneado: $_scannedCode'),
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
            SizedBox(height: 20),
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
                // ElevatedButton.icon(
                //   onPressed: _scanFromGallery,
                //   icon: Icon(Icons.photo_library),
                //   label: Text('Galería'),
                // ),
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

enum RowStatus {
  completed,
  current,
  skipped,
  pending
}

class FormulacionItem {
  bool checked;
  String secuencia;
  String instruccion;
  String temperatura;
  String tiempo;
  RowStatus status;
  String? codigoEscaneado;

  FormulacionItem({
    this.checked = false,
    required this.secuencia,
    required this.instruccion,
    required this.temperatura,
    required this.tiempo,
    this.status = RowStatus.pending,
    this.codigoEscaneado,
  });
}

class FiltracionFormulaciones extends StatefulWidget {
  @override
  _FiltracionFormulacionesState createState() => _FiltracionFormulacionesState();
}

class _FiltracionFormulacionesState extends State<FiltracionFormulaciones> {
  List<FormulacionItem> items = [];
  String selectedBombo = 'BOMBO TENIDO 5';
  final List<String> bombos = ['BOMBO TENIDO 5', 'BOMBO 2', 'BOMBO 3'];

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    items = [
      FormulacionItem(
        secuencia: '1',
        instruccion: 'Agregar agua',
        temperatura: '25°C',
        tiempo: '10 min'
      ),
      FormulacionItem(
        secuencia: '2',
        instruccion: 'Mezclar químicos',
        temperatura: '30°C',
        tiempo: '15 min'
      ),
      FormulacionItem(
        secuencia: '3',
        instruccion: 'Adicionar colorante',
        temperatura: '35°C',
        tiempo: '20 min'
      ),
      FormulacionItem(
        secuencia: '4',
        instruccion: 'Mezclar solución',
        temperatura: '40°C',
        tiempo: '25 min'
      ),
      FormulacionItem(
        secuencia: '5',
        instruccion: 'Agregar fijador',
        temperatura: '45°C',
        tiempo: '30 min'
      ),
    ];
  }

  void _updateRowStatuses(int currentIndex) {
    setState(() {
      for (int i = 0; i < items.length; i++) {
        if (i < currentIndex) {
          if (!items[i].checked) {
            items[i].status = RowStatus.skipped;
          } else {
            items[i].status = RowStatus.completed;
          }
        } else if (i == currentIndex) {
          items[i].status = RowStatus.current;
        } else {
          items[i].status = RowStatus.pending;
        }
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: Image.asset('assets/images/logo_login.png'),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back),
        ),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(230, 235, 237, 0),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bombo:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButton<String>(
                          value: selectedBombo,
                          items: bombos.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedBombo = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Formulación: F001',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Número de pesaje: P001',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Nombre de producto: Producto X',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Número de orden de producción: OP001',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('Control')),
                          DataColumn(label: Text('Secuencia')),
                          DataColumn(label: Text('Instrucción')),
                          DataColumn(label: Text('Temperatura')),
                          DataColumn(label: Text('Tiempo')),
                          DataColumn(label: Text('Scan')),
                        ],
                        rows: items.asMap().entries.map((entry) {
                          int idx = entry.key;
                          FormulacionItem item = entry.value;
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
                                    items[idx].checked = value ?? false;
                                    _updateRowStatuses(idx);
                                  });
                                },
                              )),
                              DataCell(Text(item.secuencia)),
                              DataCell(
                                TextFormField(
                                  initialValue: item.instruccion,
                                  onChanged: (value) {
                                    setState(() {
                                      items[idx].instruccion = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              DataCell(Text(item.temperatura)),
                              DataCell(Text(item.tiempo)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _openCamera(idx),
                                      icon: Icon(Icons.camera_alt),
                                    ),
                                    if (item.codigoEscaneado != null)
                                      Text(
                                        item.codigoEscaneado!,
                                        style: TextStyle(fontSize: 12),
                                      ),
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
}