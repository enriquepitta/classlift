import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¡Bienvenido!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Selecciona una opción para comenzar:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildFeatureTile(
                    icon: Icons.calendar_today,
                    title: 'Calendario Académico',
                    onTap: () {
                      // Navega a la pantalla de calendario
                      print('Calendario académico');
                    },
                  ),
                  _buildFeatureTile(
                    icon: Icons.schedule,
                    title: 'Horario de Clases',
                    onTap: () {
                      // Navega a la pantalla de horario
                      print('Horario de clases');
                    },
                  ),
                  _buildFeatureTile(
                    icon: Icons.assignment,
                    title: 'Recordatorios de Tareas',
                    onTap: () {
                      // Navega a la pantalla de recordatorios
                      print('Recordatorios de tareas');
                    },
                  ),
                  _buildFeatureTile(
                    icon: Icons.event_note,
                    title: 'Exámenes',
                    onTap: () {
                      // Navega a la pantalla de exámenes
                      print('Exámenes');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}