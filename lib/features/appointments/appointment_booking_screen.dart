import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'package:queuecare_patient/core/database/local_database.dart';
import 'package:queuecare_patient/core/services/notification_service.dart';
import 'dart:ui' as ui;

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _availabilities = [];
  Map<String, dynamic>? _selectedAvailability;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAvailabilities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailabilities() async {
    try {
      final response = await ApiClient().dio.get('/appointments/availabilities');
      if (mounted) {
        setState(() {
          _availabilities = List<Map<String, dynamic>>.from(response.data['data'])
              .where((a) => a['isBooked'] == false).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Impossible de charger les disponibilités.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedAvailability == null || _nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs et sélectionner une date.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().dio.post('/appointments/', data: {
        'availabilityId': _selectedAvailability!['id'],
        'patientName': _nameController.text,
        'patientPhone': _phoneController.text,
        'reason': _reasonController.text,
      });

      final newAppointment = response.data['data'];
      
      // Save locally
      await LocalDatabase.instance.addAppointment(newAppointment);
      
      // Notification
      NotificationService.instance.showNotification(
        "Rendez-vous demandé",
        "Votre demande pour le ${_selectedAvailability!['date']} a été envoyée."
      );

      if (mounted) {
        Navigator.pop(context, true); // true indicates success
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
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sélectionnez un créneau', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          if (_availabilities.isEmpty)
                            const Text('Aucun créneau disponible pour le moment.')
                          else
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _availabilities.length,
                                itemBuilder: (context, index) {
                                  final avail = _availabilities[index];
                                  final isSelected = _selectedAvailability == avail;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedAvailability = avail),
                                    child: Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.primaryTeal : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? AppTheme.primaryTeal : (isDark ? Colors.white12 : Colors.black12),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(avail['date'], style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white : AppTheme.slateDark), fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          Text('${avail['startTime']} - ${avail['endTime']}', style: TextStyle(color: isSelected ? Colors.white70 : AppTheme.primaryTeal)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 32),
                          Text('Vos informations', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
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
                              onPressed: _bookAppointment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Confirmer le rendez-vous', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
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
