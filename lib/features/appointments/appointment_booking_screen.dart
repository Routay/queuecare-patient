import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'package:queuecare_patient/core/database/local_database.dart';
import 'package:queuecare_patient/core/services/notification_service.dart';
import 'package:queuecare_patient/features/payment/payment_screen.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  int _currentStep = 0;
  bool _isLoading = true;
  String? _error;

  List<dynamic> _hospitals = [];
  Map<String, dynamic>? _selectedHospital;

  List<dynamic> _departments = [];
  Map<String, dynamic>? _selectedDepartment;

  List<dynamic> _doctors = [];
  Map<String, dynamic>? _selectedDoctor;

  List<dynamic> _availabilities = [];
  Map<String, dynamic>? _selectedAvailability;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadHospitals() async {
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
    setState(() { _isLoading = true; _error = null; });
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
        setState(() { _error = "Impossible de charger les départements."; _isLoading = false; });
      }
    }
  }

  Future<void> _loadDoctors() async {
    if (_selectedHospital == null || _selectedDepartment == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await ApiClient().dio.get(
        '/appointments/doctors?hospital_id=${_selectedHospital!['id']}&department=${Uri.encodeComponent(_selectedDepartment!['name'])}'
      );
      if (mounted) {
        setState(() {
          _doctors = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = "Impossible de charger les médecins."; _isLoading = false; });
      }
    }
  }

  Future<void> _loadAvailabilities() async {
    if (_selectedDoctor == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await ApiClient().dio.get('/appointments/availabilities?doctorId=${_selectedDoctor!['id']}');
      if (mounted) {
        setState(() {
          _availabilities = List<Map<String, dynamic>>.from(response.data['data'])
              .where((a) => a['isBooked'] == false).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = "Impossible de charger les disponibilités."; _isLoading = false; });
      }
    }
  }

  void _goToNextStep() {
    if (_currentStep == 0 && _selectedHospital != null) {
      setState(() => _currentStep = 1);
      _loadDepartments();
    } else if (_currentStep == 1 && _selectedDepartment != null) {
      setState(() => _currentStep = 2);
      _loadDoctors();
    } else if (_currentStep == 2 && _selectedDoctor != null) {
      setState(() => _currentStep = 3);
      _loadAvailabilities();
    } else if (_currentStep == 3 && _selectedAvailability != null) {
      setState(() => _currentStep = 4);
    }
  }

  Future<void> _processPaymentAndBooking() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir vos informations.')),
      );
      return;
    }

    // Payment Screen
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: 5000, // Fixed price for appointment
          patientName: _nameController.text,
          patientPhone: _phoneController.text,
          paymentType: 'appointment',
        ),
      ),
    );

    if (success == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final response = await ApiClient().dio.post('/appointments/', data: {
          'availabilityId': _selectedAvailability!['id'],
          'patientName': _nameController.text,
          'patientPhone': _phoneController.text,
          'reason': _reasonController.text,
        });
        
        final newAppointment = response.data['data'];
        await LocalDatabase.instance.addAppointment(newAppointment);
        
        NotificationService.instance.showNotification(
          "Rendez-vous confirmé",
          "Votre consultation avec ${_selectedDoctor!['fullName']} est validée."
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la réservation.')),
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
        title: const Text('Nouveau Rendez-vous'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.slateDark),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() => _currentStep--);
                },
              )
            : null,
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
    } else if (_currentStep == 1) {
      return _buildListScreen(
        title: 'Choisissez un Département',
        items: _departments,
        selectedItem: _selectedDepartment,
        onSelect: (d) => setState(() => _selectedDepartment = d),
        itemBuilder: (d) => d['name'],
        isDark: isDark,
      );
    } else if (_currentStep == 2) {
      return _buildListScreen(
        title: 'Choisissez un Médecin',
        items: _doctors,
        selectedItem: _selectedDoctor,
        onSelect: (d) => setState(() => _selectedDoctor = d),
        itemBuilder: (d) => d['fullName'],
        isDark: isDark,
      );
    } else if (_currentStep == 3) {
      return _buildSlotsScreen(isDark);
    } else {
      return _buildInfoFormScreen(isDark);
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
              child: const Text('Suivant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsScreen(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sélectionnez un créneau', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (_availabilities.isEmpty)
            const Text('Aucun créneau disponible pour ce médecin.')
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: _availabilities.length,
                itemBuilder: (context, index) {
                  final avail = _availabilities[index];
                  final isSelected = _selectedAvailability == avail;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvailability = avail),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryTeal : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryTeal : (isDark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            avail['date'],
                            style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54)),
                          ),
                          Text(
                            '${avail['startTime']} - ${avail['endTime']}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white : AppTheme.slateDark)),
                          ),
                        ],
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
              onPressed: _selectedAvailability == null ? null : _goToNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Suivant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFormScreen(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos informations', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildTextField(_nameController, 'Nom complet', Icons.person, isDark),
          const SizedBox(height: 16),
          _buildTextField(_phoneController, 'Numéro de téléphone', Icons.phone, isDark, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField(_reasonController, 'Motif (optionnel)', Icons.info_outline, isDark, maxLines: 3),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _processPaymentAndBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Passer au paiement (5000 FCFA)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool isDark, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : AppTheme.slateDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
        prefixIcon: maxLines == 1 ? Icon(icon, color: AppTheme.primaryTeal) : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
