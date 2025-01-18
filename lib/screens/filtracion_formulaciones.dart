import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class FiltracionFormulaciones extends StatefulWidget {
  @override
  _FiltracionFormulacionesState createState() => _FiltracionFormulacionesState();
}

class _FiltracionFormulacionesState extends State<FiltracionFormulaciones> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        // Procesar la imagen capturada
      }
    } on PlatformException catch (e) {
      print("Failed to pick image: $e");
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
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bombo:'),
                        DropdownButton<String>(
                          value: 'BOMBO TENIDO 5',
                          items: ['BOMBO TENIDO 5', 'BOMBO 2', 'BOMBO 3']
                              .map((String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ))
                              .toList(),
                          onChanged: (String? newValue) {},
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text('Formulación:'),
                    SizedBox(height: 16),
                    DataTable(
                      columns: [
                        DataColumn(label: Text('Control')),
                        DataColumn(label: Text('Producto')),
                        DataColumn(label: Text('Quimico')),
                        DataColumn(label: Text('Scan')),
                      ],
                      rows: [
                        DataRow(
                          cells: [
                            DataCell(Checkbox(
                              value: false,
                              onChanged: (bool? value) {},
                            )),
                            DataCell(Text('Producto 1')),
                            DataCell(Text('Adicionar agua')),
                            DataCell(
                              IconButton(
                                onPressed: _openCamera,
                                icon: Icon(Icons.camera_alt),
                              ),
                            ),
                          ],
                        ),
                        DataRow(
                          cells: [
                            DataCell(Checkbox(
                              value: true,
                              onChanged: (bool? value) {},
                            )),
                            DataCell(Text('Producto 2')),
                            DataCell(Text('Adicionar colorante')),
                            DataCell(
                              IconButton(
                                onPressed: _openCamera,
                                icon: Icon(Icons.camera_alt),
                              ),
                            ),
                          ],
                        ),
                        DataRow(
                          cells: [
                            DataCell(Checkbox(
                              value: false,
                              onChanged: (bool? value) {},
                            )),
                            DataCell(Text('Producto 3')),
                            DataCell(Text('Adicionar agua')),
                            DataCell(
                              IconButton(
                                onPressed: _openCamera,
                                icon: Icon(Icons.camera_alt),
                              ),
                            ),
                          ],
                        ),
                        DataRow(
                          cells: [
                            DataCell(Checkbox(
                              value: true,
                              onChanged: (bool? value) {},
                            )),
                            DataCell(Text('Producto 4')),
                            DataCell(Text('Adicionar colorante')),
                            DataCell(
                              IconButton(
                                onPressed: _openCamera,
                                icon: Icon(Icons.camera_alt),
                              ),
                            ),
                          ],
                        ),
                        DataRow(
                          cells: [
                            DataCell(Checkbox(
                              value: false,
                              onChanged: (bool? value) {},
                            )),
                            DataCell(Text('Producto 5')),
                            DataCell(Text('Adicionar agua')),
                            DataCell(
                              IconButton(
                                onPressed: _openCamera,
                                icon: Icon(Icons.camera_alt),
                              ),
                            ),
                          ],
                        ),
                        DataRow(
                          cells: [
                            DataCell(Checkbox(
                              value: true,
                              onChanged: (bool? value) {},
                            )),
                            DataCell(Text('Producto 6')),
                            DataCell(Text('Adicionar colorante')),
                            DataCell(
                              IconButton(
                                onPressed: _openCamera,
                                icon: Icon(Icons.camera_alt),
                              ),
                            ),
                          ],
                        ),
                        DataRow(
                          cells: [
                            DataCell(Checkbox(
                              value: false,
                              onChanged: (bool? value) {},
                            )),
                            DataCell(Text('Producto 7')),
                            DataCell(Text('Adicionar agua')),
                            DataCell(
                              IconButton(
                                onPressed: _openCamera,
                                icon: Icon(Icons.camera_alt),
                              ),
                            ),
                          ],
                        ),
                        DataRow(
                          cells: [
                            DataCell(Checkbox(
                              value: true,
                              onChanged: (bool? value) {},
                            )),
                            DataCell(Text('Producto 8')),
                            DataCell(Text('Adicionar colorante')),
                            DataCell(
                              IconButton(
                                onPressed: _openCamera,
                                icon: Icon(Icons.camera_alt),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: const Color.fromARGB(0, 238, 238, 238),
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        //logica 
                      }, 
                      child: Text(
                        'Reiniciar\nProceso',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        //logica 
                      }, 
                      child: Text(
                        'Fin\nProceso',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        //logica 
                      }, 
                      child: Text(
                        'Trabajo\nAdicional',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}