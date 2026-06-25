import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vos Rendez-vous'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Carte du prochain rendez-vous (mis en évidence)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryTeal.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'PROCHAIN RENDEZ-VOUS',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dr. Amadou Diallo',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Cardiologie - Hôpital Principal',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Jeu 18 Oct', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('10:30', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Bouton "Nouveau Rendez-vous"
          ElevatedButton.icon(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le calendrier de prise de rendez-vous sera affiché ici.')),
                );
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Prendre un nouveau rendez-vous'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              foregroundColor: AppTheme.primaryTeal,
              side: const BorderSide(color: AppTheme.primaryTeal, width: 2),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Historique
          Text(
            'Historique',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          _buildHistoryCard(
            context: context,
            doctor: 'Dr. Mariama Sow',
            department: 'Médecine Générale',
            date: '02 Sept 2026',
            status: 'Terminé',
            isDark: isDark,
          ),
          _buildHistoryCard(
            context: context,
            doctor: 'Dr. Ousmane Ndiaye',
            department: 'Ophtalmologie',
            date: '14 Juil 2026',
            status: 'Terminé',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required BuildContext context,
    required String doctor,
    required String department,
    required String date,
    required String status,
    required bool isDark,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
          child: const Icon(Icons.person, color: Colors.grey),
        ),
        title: Text(doctor, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(department),
            const SizedBox(height: 4),
            Text(date, style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Chip(
          label: Text(status, style: const TextStyle(fontSize: 12, color: Colors.white)),
          backgroundColor: AppTheme.success,
        ),
      ),
    );
  }
}
