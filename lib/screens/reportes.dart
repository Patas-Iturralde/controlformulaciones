// reports_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:controlformulaciones/db_helper.dart';
import 'package:controlformulaciones/services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  final bool isRemote;

  const ReportsScreen({Key? key, this.isRemote = false}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DBHelper _dbHelper = DBHelper();
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _procesos = [];
  List<Map<String, dynamic>> _procesosFiltrados = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProcesos();
    _searchController.addListener(_filterProcesos);
  }

  void _filterProcesos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _procesosFiltrados = _procesos;
      } else {
        _procesosFiltrados = _procesos.where((proceso) {
          return proceso['nrOp'].toString().contains(query) ||
                 proceso['numeroPesaje'].toString().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadProcesos() async {
    setState(() => _isLoading = true);
    try {
      if (widget.isRemote) {
        // Cargar desde la API
        final response = await _apiService.getProcesosRemoto();
        if (response['success']) {
          setState(() {
            _procesos = List<Map<String, dynamic>>.from(response['data']);
            _procesosFiltrados = _procesos;
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Error al cargar reportes remotos')),
          );
        }
      } else {
        // Cargar desde SQLite
        final procesos = await _dbHelper.getProcesos();
        setState(() {
          _procesos = procesos;
          _procesosFiltrados = procesos;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los reportes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRemote ? 'Reportes Remotos' : 'Reportes Locales'),
        actions: [
          if (!widget.isRemote)
            IconButton(
              icon: Icon(Icons.cloud),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportsScreen(isRemote: true),
                  ),
                );
              },
              tooltip: 'Ver reportes remotos',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por OP o número de pesaje',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterProcesos();
                        },
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _procesosFiltrados.isEmpty
                    ? Center(child: Text('No hay reportes disponibles'))
                    : ListView.builder(
                        itemCount: _procesosFiltrados.length,
                        itemBuilder: (context, index) {
                          final proceso = _procesosFiltrados[index];
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
                                  if (!widget.isRemote && proceso['pdfPath'] != null)
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
                                    onPressed: () async {
                                      if (widget.isRemote) {
                                        // Obtener detalles desde la API
                                        final details = await _apiService.getDetalleProcesoRemoto(proceso['id']);
                                        if (details['success']) {
                                          _showDetallesProceso(details['data']);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(details['message'] ?? 'Error al cargar detalles')),
                                          );
                                        }
                                      } else {
                                        // Obtener detalles desde SQLite
                                        final details = await _dbHelper.getReporteCompleto(proceso['id']);
                                        _showDetallesProceso(details);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
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

  void _showDetallesProceso(Map<String, dynamic> reporte) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Proceso'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('OP: ${reporte['proceso']['nrOp']}'),
              Text('Pesaje: ${reporte['proceso']['numeroPesaje']}'),
              Text('Máquina: ${reporte['proceso']['maquina']}'),
              Text('Producto: ${reporte['proceso']['producto']}'),
              Text('Fecha: ${_formatDateTime(reporte['proceso']['fecha_proceso'])}'),
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}