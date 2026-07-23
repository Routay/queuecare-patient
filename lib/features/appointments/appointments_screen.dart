import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/database/local_database.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'package:queuecare_patient/features/appointments/appointment_booking_screen.dart';
import 'package:queuecare_patient/core/widgets/shimmer_loading.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with TickerProviderStateMixin {
  late AnimationController _bgAnimController;
  late AnimationController _listAnimController;
  
  List<Map<String, dynamic>> _appointments = [];
  Map<String, dynamic>? _nextAppointment;
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
    setState(() => _isLoading = true);
    
    try {
      // Fetch from backend API to get real-time status updates
      final profile = await LocalDatabase.instance.getUserProfile();
      final phone = profile['phone'] ?? '';
      
      if (phone.isNotEmpty) {
        final response = await ApiClient().dio.get('/appointments/?patientPhone=$phone');
        final List<dynamic> serverApps = response.data['data'] ?? [];
        
        if (mounted) {
          final apps = serverApps
              .map((a) => Map<String, dynamic>.from(a))
              .toList();
          
          // Sort by date descending (newest first)
          apps.sort((a, b) {
            final dateA = a['date'] ?? '';
            final dateB = b['date'] ?? '';
            final cmp = dateB.compareTo(dateA);
            if (cmp != 0) return cmp;
            final timeA = a['startTime'] ?? '';
            final timeB = b['startTime'] ?? '';
            return timeB.compareTo(timeA);
          });
          
          // Also sync local storage
          await LocalDatabase.instance.saveAppointments(apps);
          
          // Find next upcoming appointment (confirmed or pending, date >= today)
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          Map<String, dynamic>? next;
          for (var app in apps) {
            final date = app['date'] ?? '';
            final status = app['status'] ?? '';
            if (date.compareTo(today) >= 0 && 
                (status == 'confirmed' || status == 'pending')) {
              if (next == null || date.compareTo(next['date'] ?? '') < 0) {
                next = app;
              }
            }
          }
          
          setState(() {
            _appointments = apps;
            _nextAppointment = next;
            _isLoading = false;
          });
          _listAnimController.reset();
          _listAnimController.forward();
        }
      } else {
        // Fallback to local storage if no phone
        final apps = await LocalDatabase.instance.getAppointments();
        if (mounted) {
          setState(() {
            _appointments = apps.reversed.toList();
            _nextAppointment = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Fallback to local storage on network error
      debugPrint("Erreur de chargement des rendez-vous: $e");
      final apps = await LocalDatabase.instance.getAppointments();
      if (mounted) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        Map<String, dynamic>? next;
        for (var app in apps) {
          final date = app['date'] ?? '';
          final status = app['status'] ?? '';
          if (date.compareTo(today) >= 0 && 
              (status == 'confirmed' || status == 'pending')) {
            if (next == null || date.compareTo(next['date'] ?? '') < 0) {
              next = app;
            }
          }
        }
        
        setState(() {
          _appointments = apps.reversed.toList();
          _nextAppointment = next;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  // Get status label and color
  String _getStatusLabel(String status) {
    switch (status) {
      case 'confirmed': return 'Confirmé';
      case 'cancelled': return 'Annulé';
      case 'completed': return 'Terminé';
      case 'pending':
      default: return 'En attente';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return AppTheme.success;
      case 'cancelled': return AppTheme.danger;
      case 'completed': return const Color(0xFF3B82F6); // Blue
      case 'pending':
      default: return const Color(0xFFF59E0B); // Amber/Orange
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed': return Icons.check_circle_outline;
      case 'cancelled': return Icons.cancel_outlined;
      case 'completed': return Icons.task_alt;
      case 'pending':
      default: return Icons.hourglass_bottom_rounded;
    }
  }

  String _formatDateDisplay(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      final monthNames = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
      return '${dayNames[date.weekday - 1]} ${date.day} ${monthNames[date.month - 1]}';
    } catch (_) {
      return dateStr;
    }
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
              // Carte du prochain rendez-vous — DYNAMIQUE
              if (_nextAppointment != null)
                _buildNextAppointmentCard(isDark),
              
              // Empty state when no upcoming appointment
              if (_nextAppointment == null && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today_outlined,
                          color: AppTheme.primaryTeal,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun rendez-vous à venir',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark ? Colors.white : AppTheme.slateDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Prenez un rendez-vous pour consulter un médecin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
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
                  final status = app['status'] ?? 'pending';
                  return _buildHistoryCard(
                    context: context,
                    doctor: app['doctorId'] != null ? 'Dr. ${app['doctorId']}' : 'Médecin',
                    department: app['reason']?.isNotEmpty == true ? app['reason'] : 'Consultation',
                    date: '${app['date']} à ${app['startTime']}',
                    status: _getStatusLabel(status),
                    statusColor: _getStatusColor(status),
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

  Widget _buildNextAppointmentCard(bool isDark) {
    final app = _nextAppointment!;
    final status = app['status'] ?? 'pending';
    final isConfirmed = status == 'confirmed';
    final doctorName = app['doctorId'] != null ? 'Dr. ${app['doctorId']}' : 'Médecin';
    final reason = app['reason']?.isNotEmpty == true ? app['reason'] : 'Consultation';
    final dateStr = _formatDateDisplay(app['date'] ?? '');
    final timeStr = app['startTime'] ?? '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isConfirmed ? AppTheme.primaryTeal : const Color(0xFFF59E0B)).withOpacity(isDark ? 0.2 : 0.3),
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isConfirmed
                      ? [const Color(0xFF0D9488), const Color(0xFF14B8A6)]
                      : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
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
                        child: Icon(
                          isConfirmed ? Icons.event_available : Icons.event_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'PROCHAIN RENDEZ-VOUS',
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.w700, 
                          letterSpacing: 0.5,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusLabel(status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    doctorName,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
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
                            Text(dateStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, color: Colors.white.withOpacity(0.9), size: 18),
                            const SizedBox(width: 8),
                            Text(timeStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
    );
  }

  Widget _buildHistoryCard({
    required BuildContext context,
    required String doctor,
    required String department,
    required String date,
    required String status,
    required Color statusColor,
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
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11, 
                  color: statusColor,
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

