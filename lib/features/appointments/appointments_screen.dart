import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/database/local_database.dart';
import 'package:queuecare_patient/features/appointments/appointment_booking_screen.dart';
import 'package:queuecare_patient/core/widgets/shimmer_loading.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with TickerProviderStateMixin {
  late AnimationController _bgAnimController;
  late AnimationController _listAnimController;
  
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _listAnimController.forward();
    
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final apps = await LocalDatabase.instance.getAppointments();
    if (mounted) {
      setState(() {
        _appointments = apps.reversed.toList(); // newest first
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Vos Rendez-vous',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 22,
                letterSpacing: -0.3,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppTheme.slateDark,
        ),
      ),
      body: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.0 + _bgAnimController.value * 0.3, -1.0),
                end: Alignment(1.0, 1.0 - _bgAnimController.value * 0.2),
                colors: isDark
                    ? [
                        const Color(0xFF0A0F1E),
                        const Color(0xFF0F172A),
                        Color.lerp(const Color(0xFF0F172A), const Color(0xFF1E3A8A), _bgAnimController.value * 0.3)!, // Subtle dark blue
                        const Color(0xFF0A0F1E),
                      ]
                    : [
                        const Color(0xFFF0FDFA),
                        Colors.white,
                        Color.lerp(Colors.white, const Color(0xFFDBEAFE), _bgAnimController.value * 0.4)!, // blue-100
                        const Color(0xFFF8FAFC),
                      ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadAppointments,
            color: AppTheme.primaryTeal,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
              // Carte du prochain rendez-vous (mis en évidence)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withOpacity(isDark ? 0.2 : 0.3),
                      blurRadius: 24,
                      spreadRadius: -6,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.event_outlined, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'PROCHAIN RENDEZ-VOUS',
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontWeight: FontWeight.w700, 
                                    letterSpacing: 0.5,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Dr. Amadou Diallo',
                              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cardiologie - Hôpital Principal',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded, color: Colors.white.withOpacity(0.9), size: 18),
                                      const SizedBox(width: 8),
                                      const Text('Jeu 18 Oct', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time_rounded, color: Colors.white.withOpacity(0.9), size: 18),
                                      const SizedBox(width: 8),
                                      const Text('10:30', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Decorative circle
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bouton "Nouveau Rendez-vous"
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppointmentBookingScreen()),
                    );
                    if (result == true) {
                      _loadAppointments();
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  label: const Text('Prendre un nouveau rendez-vous'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    foregroundColor: AppTheme.primaryTeal,
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0), 
                      width: 1
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              
              const SizedBox(height: 36),
              
              // Historique
              Text(
                'Vos rendez-vous',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              
              if (_isLoading)
                Column(
                  children: List.generate(3, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ShimmerLoading(width: double.infinity, height: 80, isDark: isDark),
                  )),
                )
              else if (_appointments.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Aucun rendez-vous pour le moment.', style: TextStyle(color: Colors.grey)),
                ))
              else
                ..._appointments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final app = entry.value;
                  return _buildHistoryCard(
                    context: context,
                    doctor: 'Dr. ${app['doctorId'] ?? 'Médecin'}', // In reality, fetch doctor name
                    department: 'Consultation',
                    date: '${app['date']} à ${app['startTime']}',
                    status: app['status'] == 'pending' ? 'En attente' : 'Confirmé',
                    isDark: isDark,
                    delay: index,
                  );
                }),
            ],
            ),
          ),
        ),
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
    required int delay,
  }) {
    return AnimatedBuilder(
      animation: _listAnimController,
      builder: (context, child) {
        final delayValue = delay * 0.15;
        final progress = ((_listAnimController.value - delayValue) / (1.0 - delayValue)).clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryTeal.withOpacity(0.1),
                    AppTheme.primaryTeal.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_outline, color: AppTheme.primaryTeal),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor, 
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppTheme.slateDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    department,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.primaryTeal.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Text(
                        date, 
                        style: const TextStyle(
                          color: AppTheme.primaryTeal, 
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 11, 
                  color: AppTheme.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
