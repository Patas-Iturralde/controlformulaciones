// reports_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:controlformulaciones/services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _reportes = [];
  List<Map<String, dynamic>> _reportesFiltrados = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReportes();
    _searchController.addListener(_filterReportes);
  }

  void _filterReportes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _reportesFiltrados = _reportes;
      } else {
        _reportesFiltrados = _reportes.where((reporte) {
          return reporte['new_nr_op'].toString().contains(query) ||
                 reporte['new_nr_pesaje'].toString().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadReportes() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getPesajesCerrados();
      if (response['success']) {
        setState(() {
          _reportes = List<Map<String, dynamic>>.from(response['data']);
          _reportesFiltrados = _reportes;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Error al cargar reportes')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los reportes: $e')),
      );
    }
  }

  //Generar PDF
  Future<void> _generarPDF(Map<String, dynamic> reporte) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Detalle de Proceso',
                        style: pw.TextStyle(fontSize: 24)),
                    pw.Divider(),
                    pw.Text('OP: ${reporte['new_nr_op']}',
                        style: pw.TextStyle(fontSize: 16)),
                    pw.Text('Máquina: ${reporte['new_maquina']}',
                        style: pw.TextStyle(fontSize: 16)),
                    pw.Text('Producto: ${reporte['new_producto_op']}',
                        style: pw.TextStyle(fontSize: 16)),
                    pw.Text('Fecha: ${reporte['fecha_apertura']}',
                        style: pw.TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),    // Secuencia
                  1: const pw.FlexColumnWidth(2),    // Instrucción
                  2: const pw.FlexColumnWidth(2),    // Producto
                  3: const pw.FlexColumnWidth(1.5),  // Cantidad
                  4: const pw.FlexColumnWidth(1),    // Temperatura
                  5: const pw.FlexColumnWidth(2),    // Observación
                  6: const pw.FlexColumnWidth(1.5),  // Inicio
                  7: const pw.FlexColumnWidth(1.5),  // Fin
                },
                children: [
                  // Encabezado
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      'Secuencia',
                      'Instrucción',
                      'Producto',
                      'Cantidad',
                      'Temp.',
                      'Observación',
                      'Inicio',
                      'Fin',
                    ].map((text) => pw.Container(
                      alignment: pw.Alignment.center,
                      padding: pw.EdgeInsets.all(5),
                      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    )).toList(),
                  ),
                  // Filas de datos
                  ...(reporte['secuencias'] as List).map((secuencia) {
                    return pw.TableRow(
                      children: [
                        _buildPdfCell(secuencia['new_sec'].toString()),
                        _buildPdfCell(secuencia['new_oper_maquina'] ?? ''),
                        _buildPdfCell(secuencia['new_producto_pesaje'] ?? ''),
                        _buildPdfCell(secuencia['new_ctd_explosion']?.toString() ?? ''),
                        _buildPdfCell(secuencia['new_temperatura'] != 0 ? '${secuencia['new_temperatura']}°C' : ''),
                        _buildPdfCell(secuencia['new_observacion'] ?? ''),
                        _buildPdfCell(_formatDateTime(secuencia['hora_inicio'])),
                        _buildPdfCell(_formatDateTime(secuencia['hora_fin'])),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );

      // Guardar el PDF
      final directory = await getApplicationDocumentsDirectory();
      final String pdfPath = '${directory.path}/reporte_${reporte['new_nr_op']}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(pdfPath);
      await file.writeAsBytes(await pdf.save());

      // Abrir el PDF
      await OpenFile.open(pdfPath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF generado correctamente')),
      );

    } catch (e) {
      print('Error generando PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar el PDF')),
      );
    }
  }

  pw.Widget _buildPdfCell(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reportes de Procesos'),
      ),
      body: Column(
        children: [
          //Buscador por OP o pesaje
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
                          _filterReportes();
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
                : _reportesFiltrados.isEmpty
                    ? Center(child: Text('No hay reportes disponibles'))
                    : ListView.builder(
                        itemCount: _reportesFiltrados.length,
                        itemBuilder: (context, index) {
                          final reporte = _reportesFiltrados[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: ListTile(
                              title: Text(
                                'OP: ${reporte['new_nr_op']} - Pesaje: ${reporte['new_nr_pesaje']}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Máquina: ${reporte['new_maquina']}'),
                                  Text('Producto: ${reporte['new_producto_op']}'),
                                  Text('Fecha: ${_formatDateTime(reporte['fecha_apertura'])}'),
                                  Text('Situación: ${reporte['new_situacion']}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.picture_as_pdf),
                                    onPressed: () => _generarPDF(reporte),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.info_outline),
                                    onPressed: () => _showDetallesReporte(reporte),
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

  //Formatea la fecha
  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  //Mostrar reportes
  void _showDetallesReporte(Map<String, dynamic> reporte) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Proceso'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('OP: ${reporte['new_nr_op']}'),
              Text('Pesaje: ${reporte['new_nr_pesaje']}'),
              Text('Máquina: ${reporte['new_maquina']}'),
              Text('Producto: ${reporte['new_producto_op']}'),
              Text('Código: ${reporte['new_cod_producto']}'),
              Text('Fecha: ${_formatDateTime(reporte['fecha_apertura'])}'),
              Text('Situación: ${reporte['new_situacion']}'),
              Divider(),
              Text('Secuencias:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(reporte['secuencias'] as List).map((secuencia) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Secuencia ${secuencia['new_sec']}'),
                        Text('Instrucción: ${secuencia['new_oper_maquina']}'),
                        if (secuencia['new_producto_pesaje'] != null)
                          Text('Producto: ${secuencia['new_producto_pesaje']}'),
                        if (secuencia['new_ctd_explosion'] != null)
                          Text('Cantidad: ${secuencia['new_ctd_explosion']}'),
                        if (secuencia['new_temperatura'] != null && secuencia['new_temperatura'] != 0)
                          Text('Temperatura: ${secuencia['new_temperatura']}°C'),
                        if (secuencia['new_observacion'] != null)
                          Text('Observación: ${secuencia['new_observacion']}'),
                        if (secuencia['hora_inicio'] != null)
                          Text('Inicio: ${_formatDateTime(secuencia['hora_inicio'])}'),
                        if (secuencia['hora_fin'] != null)
                          Text('Fin: ${_formatDateTime(secuencia['hora_fin'])}'),
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