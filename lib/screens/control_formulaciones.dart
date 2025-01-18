import 'package:controlformulaciones/screens/filtracion_formulaciones.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ControlFormulaciones extends StatefulWidget {
  @override
  _ControlFormulacionesState createState() => _ControlFormulacionesState();
}

class _ControlFormulacionesState extends State<ControlFormulaciones> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
        
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Manejar la respuesta de la notificación si es necesario
      },
    );
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
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromRGBO(211, 148, 0, 1),
              ),
              child: Text(
                'Configuracion\ngeneral',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
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
            ListTile(
              leading: Icon(Icons.warning),
              title: Text('Emitir alertas de\ntrabajo adicional'),
              onTap: () {
                Navigator.pop(context);
                // Navegar a la página de configuración
              },
            ),
            ListTile(
              leading: Icon(Icons.document_scanner),
              title: Text('Generacion de\nreportes'),
              onTap: () {
                Navigator.pop(context);
                // Navegar a la página de acerca de
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(context);
                // Cerrar sesión
              },
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Text('Control de Formulaciones',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )),
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
      decoration: InputDecoration(
        hintText: 'Buscar',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }

  Widget _buildItemList() {
    return ListView.builder(
      itemCount: 3, // Replace with your actual item count
      itemBuilder: (context, index) {
        return _buildItem(context, index);
      },
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text('B${index + 1}'),
          backgroundColor: Color.fromRGBO(185, 185, 185, 1),
        ),
        title: Text(
          'Sec${index + 1} / 15:45',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Bombo ${index + 1}: Anilina black hec',
        ),
        trailing: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FiltracionFormulaciones()), // Reemplaza OtraPagina con la página de destino
            );
          },
          icon: Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }
}
