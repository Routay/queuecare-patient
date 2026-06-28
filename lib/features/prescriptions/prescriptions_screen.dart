import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/widgets/glass_container.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'package:queuecare_patient/core/database/local_database.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  bool _isLoading = true;
  List<dynamic> _prescriptions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  Future<void> _fetchPrescriptions() async {
    try {
      setState(() { _isLoading = true; _error = null; });
      
      // Get active ticket
      final ticket = await LocalDatabase.instance.getActiveTicket();
      if (ticket == null || ticket['id'] == null) {
        setState(() {
          _isLoading = false;
          _error = "Aucun ticket actif. Impossible de trouver vos ordonnances.";
        });
        return;
      }

      final String ticketId = ticket['id'].toString();
      
      // Fetch prescriptions from backend
      final response = await ApiClient().dio.get('/consultations/prescriptions/patient/$ticketId');
      
      if (mounted) {
        setState(() {
          _prescriptions = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Erreur lors de la récupération des ordonnances : $e";
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return "${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Mes Ordonnances'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [AppTheme.slateLight, Colors.white, AppTheme.sageLight.withOpacity(0.3)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
              : _error != null
                  ? _buildErrorState()
                  : _prescriptions.isEmpty
                      ? _buildEmptyState()
                      : _buildPrescriptionsList(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.danger),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchPrescriptions,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
              child: const Text('Réessayer'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Aucune ordonnance trouvée',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les ordonnances prescrites lors de vos\nconsultations s\'afficheront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsList() {
    return RefreshIndicator(
      onRefresh: _fetchPrescriptions,
      color: AppTheme.primaryTeal,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _prescriptions.length,
        itemBuilder: (context, index) {
          final p = _prescriptions[index];
          final isDelivered = p['status'] == 'delivered';
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassContainer(
              blur: isDark ? 20 : 10,
              opacity: isDark ? 0.05 : 0.6,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.2)),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medical_services, color: AppTheme.primaryTeal, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Dr. ${p['doctorName']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDelivered ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDelivered ? AppTheme.success : AppTheme.warning),
                        ),
                        child: Text(
                          isDelivered ? 'Délivrée' : 'En attente',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDelivered ? AppTheme.success : AppTheme.warning,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(p['date']),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(height: 24, color: Colors.grey),
                  const Text(
                    'Médicaments prescrits :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...(p['medicines'] as List).map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${m['name']} (x${m['quantity']})',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (m['dosage'] != null && m['dosage'].toString().isNotEmpty)
                                Text(
                                  m['dosage'],
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                )
                            ],
                          ),
                        )
                      ],
                    ),
                  )),
                  if (p['notes'] != null && p['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Notes: ${p['notes']}',
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    )
                  ],
                  if (isDelivered) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Délivrée par ${p['deliveredBy']} à la pharmacie.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.success),
                    )
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
