import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'package:queuecare_patient/core/database/local_database.dart';
import 'package:queuecare_patient/core/widgets/shimmer_loading.dart';
import 'package:queuecare_patient/features/payment/payment_screen.dart';

class QueueBookingScreen extends StatefulWidget {
  const QueueBookingScreen({super.key});

  @override
  State<QueueBookingScreen> createState() => _QueueBookingScreenState();
}

class _QueueBookingScreenState extends State<QueueBookingScreen> {
  int _currentStep = 0;
  bool _isLoading = true;
  String? _error;

  List<dynamic> _hospitals = [];
  Map<String, dynamic>? _selectedHospital;

  List<dynamic> _departments = [];
  Map<String, dynamic>? _selectedDepartment;

  // Patient profile loaded from local storage
  String _patientName = 'Patient';
  String _patientPhone = 'N/A';

  @override
  void initState() {
    super.initState();
    _loadProfileAndHospitals();
  }

  Future<void> _loadProfileAndHospitals() async {
    // Load saved profile in parallel with hospitals
    final profile = await LocalDatabase.instance.getUserProfile();
    if (mounted) {
      setState(() {
        _patientName = (profile['name'] as String?)?.isNotEmpty == true
            ? profile['name'] as String
            : 'Patient';
        _patientPhone = (profile['phone'] as String?)?.isNotEmpty == true
            ? profile['phone'] as String
            : 'N/A';
      });
    }

    try {
      final response = await ApiClient().dio.get('/hospitals/');
      if (mounted) {
        setState(() {
          _hospitals = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Impossible de charger les hôpitaux.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDepartments() async {
    if (_selectedHospital == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient().dio.get('/queue/${_selectedHospital!['id']}/departments/list');
      if (mounted) {
        setState(() {
          _departments = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Impossible de charger les départements.";
          _isLoading = false;
        });
      }
    }
  }

  void _goToNextStep() {
    if (_currentStep == 0 && _selectedHospital != null) {
      setState(() => _currentStep = 1);
      _loadDepartments();
    } else if (_currentStep == 1 && _selectedDepartment != null) {
      _processPaymentAndTicket();
    }
  }

  Future<void> _processPaymentAndTicket() async {
    // Navigate to Payment Screen
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: 1500,
          patientName: _patientName,
          patientPhone: _patientPhone,
          paymentType: 'ticket',
        ),
      ),
    );

    if (success == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final response = await ApiClient().dio.post('/queue/ticket', data: {
          'hospital_id': _selectedHospital!['id'],
          'department': _selectedDepartment!['name'],
        });
        
        final ticket = response.data;
        if (mounted) {
          Navigator.pop(context, ticket);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la création du ticket.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Prendre un ticket'),
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
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _buildStepContent(isDark),
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    if (_currentStep == 0) {
      return _buildListScreen(
        title: 'Choisissez un Hôpital',
        items: _hospitals,
        selectedItem: _selectedHospital,
        onSelect: (h) => setState(() => _selectedHospital = h),
        itemBuilder: (h) => h['name'],
        isDark: isDark,
      );
    } else {
      return _buildListScreen(
        title: 'Choisissez un Département',
        items: _departments,
        selectedItem: _selectedDepartment,
        onSelect: (d) => setState(() => _selectedDepartment = d),
        itemBuilder: (d) => '${d['name']} (${d['waitingCount']} en attente)',
        isDark: isDark,
      );
    }
  }

  Widget _buildListScreen({
    required String title,
    required List<dynamic> items,
    required dynamic selectedItem,
    required Function(dynamic) onSelect,
    required String Function(dynamic) itemBuilder,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (items.isEmpty)
            const Text('Aucun élément disponible.')
          else
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedItem == item;
                  return GestureDetector(
                    onTap: () => onSelect(item),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryTeal : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryTeal : (isDark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                      child: Text(
                        itemBuilder(item),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : (isDark ? Colors.white : AppTheme.slateDark),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: selectedItem == null ? null : _goToNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _currentStep == 1 ? 'Passer au paiement' : 'Suivant', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
              ),
            ),
          ),
        ],
      ),
    );
  }
}
