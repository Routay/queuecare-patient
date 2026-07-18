import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/database/local_database.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'package:queuecare_patient/core/widgets/shimmer_loading.dart';
import 'dart:ui' as ui;

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _record;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    try {
      final ticket = await LocalDatabase.instance.getActiveTicket();
      if (ticket == null || ticket['id'] == null) {
        if (mounted) {
          setState(() {
            _error = "Aucun ticket actif trouvé. Votre dossier est lié à votre passage actuel.";
            _isLoading = false;
          });
        }
        return;
      }

      final response = await ApiClient().dio.get('/queue/history/patient/${ticket['id']}');
      
      if (mounted) {
        setState(() {
          _record = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Impossible de charger le dossier médical.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Dossier Médical'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.slateDark),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF0A0F1E)]
                : [const Color(0xFFF0FDFA), Colors.white],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadRecord,
            color: AppTheme.primaryTeal,
            child: _isLoading
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ShimmerLoading(width: 150, height: 24, isDark: isDark),
                      const SizedBox(height: 16),
                      ShimmerLoading(width: double.infinity, height: 80, isDark: isDark, borderRadius: 16),
                      const SizedBox(height: 32),
                      ShimmerLoading(width: 150, height: 24, isDark: isDark),
                      const SizedBox(height: 16),
                      ShimmerLoading(width: double.infinity, height: 120, isDark: isDark, borderRadius: 16),
                    ],
                  )
                : _error != null
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      )
                    : _buildContent(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final visitInfo = _record?['visitInfo'];
    final prescriptions = _record?['prescriptions'] as List<dynamic>? ?? [];

    if (visitInfo == null && prescriptions.isEmpty) {
      return const Center(
        child: Text("Votre dossier pour cette visite est encore vide.", style: TextStyle(fontSize: 16)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (visitInfo != null) ...[
          Text('Consultation', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildInfoCard(
            isDark: isDark,
            icon: Icons.medical_services_outlined,
            title: visitInfo['department'] ?? 'Département',
            subtitle: 'Vu par ${visitInfo['treatedBy'] ?? 'le médecin'}',
            trailing: visitInfo['status'] == 'treated' ? 'Terminé' : 'En cours',
          ),
          const SizedBox(height: 32),
        ],
        
        Text('Ordonnances', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (prescriptions.isEmpty)
          const Text("Aucune ordonnance n'a été émise.")
        else
          ...prescriptions.map((p) => _buildPrescriptionCard(p, isDark)).toList(),
      ],
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryTeal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(trailing, style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> prescription, bool isDark) {
    final medicines = prescription['medicines'] as List<dynamic>? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Le ${prescription['date']?.substring(0, 10) ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Icon(prescription['status'] == 'delivered' ? Icons.check_circle : Icons.pending, 
                   color: prescription['status'] == 'delivered' ? AppTheme.success : AppTheme.warning),
            ],
          ),
          const SizedBox(height: 8),
          Text('Dr. ${prescription['doctorName'] ?? ''}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
          if (prescription['notes'] != null && prescription['notes'].isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Notes: ${prescription['notes']}', style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
          const Divider(height: 32),
          const Text('Médicaments:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...medicines.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.medication_liquid, size: 16, color: AppTheme.primaryTeal),
                const SizedBox(width: 8),
                Expanded(child: Text('${m['name']} x${m['quantity']}')),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
