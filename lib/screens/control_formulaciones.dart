import 'package:controlformulaciones/screens/filtracion_formulaciones.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Modelo para los items de formulación
class FormulationItem {
  final String id;
  final String secuencia;
  final String hora;
  final String bombo;
  final String descripcion;

  FormulationItem({
    required this.id,
    required this.secuencia,
    required this.hora,
    required this.bombo,
    required this.descripcion,
  });
}

class ControlFormulaciones extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ControlFormulaciones({Key? key, this.userData}) : super(key: key);

  @override
  _ControlFormulacionesState createState() => _ControlFormulacionesState();
}

class _ControlFormulacionesState extends State<ControlFormulaciones> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late String userRole;
  late String userName;
  final TextEditingController _searchController = TextEditingController();

  // Lista de todos los items
  final List<FormulationItem> _allItems = [
    FormulationItem(
      id: 'B1',
      secuencia: 'Sec1',
      hora: '15:45',
      bombo: 'Bombo 1',
      descripcion: 'Anilina black hec',
    ),
    FormulationItem(
      id: 'B2',
      secuencia: 'Sec2',
      hora: '15:45',
      bombo: 'Bombo 2',
      descripcion: 'Anilina black hec',
    ),
    FormulationItem(
      id: 'B3',
      secuencia: 'Sec3',
      hora: '15:45',
      bombo: 'Bombo 3',
      descripcion: 'Anilina black hec',
    ),
  ];

  // Lista filtrada
  late List<FormulationItem> _filteredItems;

  @override
  void initState() {
    super.initState();
    userRole = widget.userData?['rol'] ?? '';
    userName = widget.userData?['nombre'] ?? 'Usuario';
    _filteredItems = _allItems;
    _searchController.addListener(_filterItems);
    
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
        
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      },
    );
  }

  void _filterItems() {
    final String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems.where((item) {
          return item.secuencia.toLowerCase().contains(query) ||
                 item.bombo.toLowerCase().contains(query) ||
                 item.descripcion.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Notificación',
      'Notificaciones activadas',
      platformChannelSpecifics,
      payload: 'item x',
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
              'Bienvenido:\n$userName',
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
          _showNotification();
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
          Navigator.pop(context);
          Navigator.of(context).pushReplacementNamed('/login');
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Text(
          'Control de Formulaciones',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          )
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
          child: _buildSearchBar(),
        ),
        Expanded(
          child: _buildItemList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por secuencia, bombo o descripción',
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
    );
  }

  Widget _buildItemList() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron resultados',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return _buildItem(context, _filteredItems[index]);
      },
    );
  }

  Widget _buildItem(BuildContext context, FormulationItem item) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(item.id),
          backgroundColor: Color.fromRGBO(185, 185, 185, 1),
        ),
        title: Text(
          '${item.secuencia} / ${item.hora}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${item.bombo}: ${item.descripcion}',
        ),
        trailing: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FiltracionFormulaciones()),
            );
          },
          icon: Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}