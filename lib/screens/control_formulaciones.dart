import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:controlformulaciones/screens/filtracion_formulaciones.dart';
import 'package:controlformulaciones/api_service.dart';
import 'package:controlformulaciones/screens/login.dart';

enum RowStatus { completed, current, skipped, pending }

class FormulationItem {
  final int idPesagemItem;
  final int nrOp;
  final String codProducto;
  final String productoOp;
  final String maquina;
  final int sec;
  final String operMaquina;
  final double temperatura;
  final int minutos;
  final String situacion;
  final String? fechaApertura;
  bool checked;
  RowStatus status;
  String? codigoEscaneado;

  FormulationItem({
    required this.idPesagemItem,
    required this.nrOp,
    required this.codProducto,
    required this.productoOp,
    required this.maquina,
    required this.sec,
    required this.operMaquina,
    required this.temperatura,
    required this.minutos,
    required this.situacion,
    required this.fechaApertura,
    this.checked = false,
    this.status = RowStatus.pending,
    this.codigoEscaneado,
  });

  factory FormulationItem.fromJson(Map<String, dynamic> json) {
    return FormulationItem(
      idPesagemItem: json['ID_PESAGEM_ITEM'],
      nrOp: json['NR_OP'],
      codProducto: json['COD_PRODUCTO'],
      productoOp: json['PRODUCTO_OP'],
      maquina: json['MAQUINA'],
      sec: json['SEC'],
      operMaquina: json['OPER_MAQUINA'],
      temperatura: json['TEMPERATURA']?.toDouble() ?? 0.0,
      minutos: json['MINUTOS'] ?? 0,
      situacion: json['SITUACION'],
      fechaApertura: json['FECHA_APERTURA'] ?? '',
    );
  }
}

class ControlFormulaciones extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ControlFormulaciones({Key? key, this.userData}) : super(key: key);

  @override
  _ControlFormulacionesState createState() => _ControlFormulacionesState();
}

class _ControlFormulacionesState extends State<ControlFormulaciones> {
  final ApiService _apiService = ApiService();
  late String userRole;
  late String userName;
  List<FormulationItem> items = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<FormulationItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    userRole = widget.userData?['rol'] ?? '';
    userName = widget.userData?['nombre'] ?? 'Usuario';
    _loadPesajesAbiertos();
    _searchController.addListener(_filterItems);
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = query.isEmpty
          ? items
          : items
              .where((item) =>
                  item.productoOp.toLowerCase().contains(query) ||
                  item.maquina.toLowerCase().contains(query) ||
                  item.nrOp.toString().contains(query))
              .toList();
    });
  }

  Future<void> _loadPesajesAbiertos() async {
    try {
      final response = await _apiService.getPesajesAbiertos();
      if (response['success']) {
        setState(() {
          items = (response['data'] as List)
              .map((item) => FormulationItem.fromJson(item))
              .toList();
          _filteredItems = items;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading pesajes: $e');
      setState(() => isLoading = false);
    }
  }

  Widget _buildItemList() {
    if (isLoading) return Center(child: CircularProgressIndicator());
    if (_filteredItems.isEmpty)
      return Center(child: Text('No hay pesajes activos'));

    var groupedItems =
        groupBy(_filteredItems, (FormulationItem item) => item.maquina);

    return ListView.builder(
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        String bombo = groupedItems.keys.elementAt(index);
        List<FormulationItem> bomboItems = groupedItems[bombo]!;

        var groupedByPesaje =
            groupBy(bomboItems, (FormulationItem item) => item.nrOp)
                .map((key, value) => MapEntry(key, value.first));

        return ExpansionTile(
          title: Text(bombo, style: TextStyle(fontWeight: FontWeight.bold)),
          children: groupedByPesaje.entries
              .map((pesajeGroup) => Card(
                    child: ListTile(
                      title: Text('Pesaje: ${pesajeGroup.key}'),
                      subtitle: Text(
                          'Fecha: ${pesajeGroup.value.fechaApertura?.split('T')[0]}'),
                      trailing: IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FiltracionFormulaciones(
                              pesajeItem: pesajeGroup.value,
                              bomboItems: bomboItems
                                  .where((item) => item.nrOp == pesajeGroup.key)
                                  .toList(),
                            ),
                          ),
                        ),
                        icon: Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  List<Widget> _buildDrawerItems() {
    List<Widget> items = [
      DrawerHeader(
        decoration: BoxDecoration(
          color: Color.fromRGBO(211, 148, 0, 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenid@\n$userName',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Rol: $userRole',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      ListTile(
        leading: Icon(Icons.notifications),
        title: Text('Activar\nnotificaciones'),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    ];

    if (userRole == 'S') {
      items.addAll([
        ListTile(
          leading: Icon(Icons.warning),
          title: Text('Emitir alertas de\ntrabajo adicional'),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.document_scanner),
          title: Text('Generacion de\nreportes'),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ]);
    }

    items.add(
      ListTile(
        leading: Icon(Icons.exit_to_app),
        title: Text('Cerrar sesión'),
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => Login()),
            (Route<dynamic> route) => false,
          );
        },
      ),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: Image.asset('assets/images/logo_login.png'),
        ),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(230, 235, 237, 0),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: _buildDrawerItems(),
        ),
      ),
      body: Column(
        children: [
          Text(
            'Control de Formulaciones',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Pesajes Activos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por producto, máquina u OP',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterItems();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _buildItemList(),
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
