import 'package:flutter/material.dart';
import 'package:mobile/models/estacion.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/auth_service.dart';
import 'add_estacion.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Estacion>> _futureEstaciones;

  @override
  void initState() {
    super.initState();
    _refreshEstaciones();
  }

  void _refreshEstaciones() {
    setState(() {
      _futureEstaciones = ApiService().fetchEstaciones();
    });
  }

  void _logout() async {
    // 1. Borra la llave jwt_token de la memoria local
    await AuthService().logout();
    
    if (!mounted) return;
    // 2. Devuelve al usuario al LoginScreen eliminando el historial de rutas
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estaciones SMAT'),
        actions: [
          // Botón de Logout solicitado en el criterio de evaluación
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<Estacion>>(
        future: _futureEstaciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay estaciones registradas.'));
          }

          final estaciones = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshEstaciones(),
            child: ListView.builder(
              itemCount: estaciones.length,
              itemBuilder: (context, index) {
                final estacion = estaciones[index];
                return ListTile(
                  leading: const Icon(Icons.satellite_alt),
                  title: Text(estacion.nombre),
                  subtitle: Text(estacion.ubicacion),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navega a la pantalla de agregar y espera el resultado
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEstacionScreen()),
          );
          // Si guardó con éxito (retornó true), refresca la lista automáticamente
          if (resultado == true) {
            _refreshEstaciones();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}