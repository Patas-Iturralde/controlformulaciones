// reports_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:controlformulaciones/db_helper.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _procesos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProcesos();
  }

  Future<void> _loadProcesos() async {
    setState(() => _isLoading = true);
    try {
      final procesos = await _dbHelper.getAllProcesos();
      setState(() {
        _procesos = procesos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando procesos: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los reportes')),
      );
    }
  }

  Future<void> _mostrarDetallesProceso(Map<String, dynamic> proceso) async {
    try {
      final reporte = await _dbHelper.getReporteCompleto(proceso['id']);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Detalles del Proceso'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('OP: ${proceso['nrOp']}'),
                Text('Pesaje: ${proceso['numeroPesaje']}'),
                Text('Máquina: ${proceso['maquina']}'),
                Text('Producto: ${proceso['producto']}'),
                Text('Fecha: ${_formatDateTime(proceso['fecha_proceso'])}'),
                Divider(),
                Text('Secuencias:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...reporte['secuencias'].map<Widget>((secuencia) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Secuencia ${secuencia['secuencia']}'),
                          Text('Instrucción: ${secuencia['instruccion']}'),
                          if (secuencia['producto'] != null)
                            Text('Producto: ${secuencia['producto']}'),
                          Text('Temperatura: ${secuencia['temperatura']}°C'),
                          Text('Tiempo: ${secuencia['tiempo']} min'),
                          if (secuencia['hora_inicio'] != null)
                            Text('Inicio: ${_formatDateTime(secuencia['hora_inicio'])}'),
                          if (secuencia['hora_fin'] != null)
                            Text('Fin: ${_formatDateTime(secuencia['hora_fin'])}'),
                          if (secuencia['observacion'] != null)
                            Text('Observación: ${secuencia['observacion']}'),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
            if (proceso['pdfPath'] != null)
              ElevatedButton(
                onPressed: () async {
                  try {
                    final file = File(proceso['pdfPath']);
                    if (await file.exists()) {
                      await OpenFile.open(proceso['pdfPath']);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PDF no encontrado')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al abrir el PDF')),
                    );
                  }
                },
                child: Text('Ver PDF'),
              ),
          ],
        ),
      );
    } catch (e) {
      print('Error mostrando detalles: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los detalles')),
      );
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reportes de Formulaciones'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadProcesos,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _procesos.isEmpty
              ? Center(child: Text('No hay reportes disponibles'))
              : ListView.builder(
                  itemCount: _procesos.length,
                  itemBuilder: (context, index) {
                    final proceso = _procesos[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        title: Text(
                          'OP: ${proceso['nrOp']} - Pesaje: ${proceso['numeroPesaje']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Máquina: ${proceso['maquina']}'),
                            Text('Producto: ${proceso['producto']}'),
                            Text('Fecha: ${_formatDateTime(proceso['fecha_proceso'])}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (proceso['pdfPath'] != null)
                              IconButton(
                                icon: Icon(Icons.picture_as_pdf),
                                onPressed: () async {
                                  try {
                                    final file = File(proceso['pdfPath']);
                                    if (await file.exists()) {
                                      await OpenFile.open(proceso['pdfPath']);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('PDF no encontrado')),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al abrir el PDF')),
                                    );
                                  }
                                },
                              ),
                            IconButton(
                              icon: Icon(Icons.info_outline),
                              onPressed: () => _mostrarDetallesProceso(proceso),
                            ),
                          ],
                        ),
                        onTap: () => _mostrarDetallesProceso(proceso),
                      ),
                    );
                  },
                ),
    );
  }
}