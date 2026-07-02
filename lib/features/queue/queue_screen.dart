import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/localization/app_localizations.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/network/queue_socket.dart';
import 'package:queuecare_patient/core/widgets/glass_container.dart';

class QueueScreen extends StatefulWidget {
  final Map<String, dynamic>? initialTicket;
  const QueueScreen({super.key, this.initialTicket});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> with TickerProviderStateMixin {
  int _currentPosition = 0;
  int _estimatedWaitTime = 0;
  String _ticketNumber = '--';
  final QueueSocket _socket = QueueSocket();
  bool _isConnected = false;
  late AnimationController _pulseController;
  late AnimationController _bgWaveController;
  late AnimationController _numberAnimController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _bgWaveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    
    _numberAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    if (widget.initialTicket != null) {
      _setupFromTicket(widget.initialTicket!);
    }
  }

  @override
  void didUpdateWidget(covariant QueueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTicket != null && oldWidget.initialTicket?['id'] != widget.initialTicket?['id']) {
      _setupFromTicket(widget.initialTicket!);
    }
  }

  void _setupFromTicket(Map<String, dynamic> ticket) {
    setState(() {
      _ticketNumber = ticket['ticketNumber'] ?? '--';
      _currentPosition = ticket['position'] ?? 0;
      _estimatedWaitTime = ticket['estimatedWaitTime'] ?? 0;
      _isConnected = true;
    });
    _numberAnimController.forward(from: 0);

    final ticketId = ticket['id'];
    if (ticketId != null) {
      _socket.connect(ticketId);
      _socket.stream.listen((data) {
        if (mounted && data['type'] == 'queue_update') {
          setState(() {
            _currentPosition = data['position'];
            _estimatedWaitTime = data['estimatedWaitTime'];
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bgWaveController.dispose();
    _numberAnimController.dispose();
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isConnected) {
      return _buildEmptyState(context, loc, isDark);
    }

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgWaveController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.0 + _bgWaveController.value * 0.2, -1.0),
                end: Alignment(1.0, 1.0 - _bgWaveController.value * 0.15),
                colors: isDark
                    ? [
                        const Color(0xFF0A0F1E),
                        const Color(0xFF0F172A),
                        Color.lerp(const Color(0xFF0F172A), const Color(0xFF0D3530), _bgWaveController.value * 0.4)!,
                        const Color(0xFF0A0F1E),
                      ]
                    : [
                        const Color(0xFFF0FDFA),
                        Colors.white,
                        Color.lerp(Colors.white, const Color(0xFFCCFBF1), _bgWaveController.value * 0.4)!,
                        const Color(0xFFF8FAFC),
                      ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Image.asset(
                        'assets/images/queue_illustration.png',
                        width: 28,
                        height: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.get('queue'),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 26,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Suivi en temps réel',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Carte Principale (Ticket) — Premium Glass
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final glowOpacity = 0.15 + (_pulseController.value * 0.15);
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryTeal.withOpacity(glowOpacity * 0.5),
                            blurRadius: 40,
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: GlassContainer(
                        blur: 28,
                        opacity: isDark ? 0.1 : 0.7,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppTheme.primaryTeal.withOpacity(0.25 + _pulseController.value * 0.1),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                        child: Column(
                          children: [
                            // Ticket label
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                loc.get('your_number'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryTeal,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Big ticket number with glow
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryTeal.withOpacity(glowOpacity),
                                    blurRadius: 50,
                                    spreadRadius: -15,
                                  ),
                                ],
                              ),
                              child: Text(
                                _ticketNumber,
                                style: const TextStyle(
                                  fontSize: 72,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryTeal,
                                  letterSpacing: 6,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Divider
                            Container(
                              height: 1,
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Stats row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatCard(
                                  _currentPosition.toString(), 
                                  loc.get('people_waiting'),
                                  AppTheme.warning,
                                  Icons.people_outline,
                                  isDark,
                                ),
                                Container(
                                  height: 50,
                                  width: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        isDark ? Colors.white24 : Colors.black12,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                _buildStatCard(
                                  '$_estimatedWaitTime min', 
                                  loc.get('estimated_time'),
                                  AppTheme.success,
                                  Icons.timer_outlined,
                                  isDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const Spacer(),
                
                // Alert: prepare ID
                if (_currentPosition <= 2 && _currentPosition > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.danger.withOpacity(isDark ? 0.15 : 0.08),
                          AppTheme.danger.withOpacity(isDark ? 0.08 : 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.danger.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            loc.get('prepare_id'),
                            style: const TextStyle(
                              color: AppTheme.danger, 
                              fontWeight: FontWeight.w600, 
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                // Your turn banner
                if (_currentPosition == 0)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF059669), AppTheme.primaryTeal],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.success.withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: -6,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.check_circle, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "C'est votre tour !",
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.w800, 
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Veuillez vous diriger vers le bureau.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations loc, bool isDark) {
    return AnimatedBuilder(
      animation: _bgWaveController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF0A0F1E),
                      const Color(0xFF0F172A),
                      Color.lerp(const Color(0xFF0F172A), const Color(0xFF0D3530), _bgWaveController.value * 0.3)!,
                    ]
                  : [
                      const Color(0xFFF0FDFA),
                      Colors.white,
                      Color.lerp(Colors.white, const Color(0xFFCCFBF1), _bgWaveController.value * 0.3)!,
                    ],
            ),
          ),
          child: child,
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Empty state illustration
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryTeal.withOpacity(0.08),
                      AppTheme.primaryTeal.withOpacity(0.15),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Image.asset(
                      'assets/images/queue_illustration.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                "Aucun ticket actif",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Scannez le QR Code à l'hôpital\nou prenez un rendez-vous.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  height: 1.6,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryTeal.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner, color: AppTheme.primaryTeal, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Scanner un QR Code',
                      style: TextStyle(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color, IconData icon, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
