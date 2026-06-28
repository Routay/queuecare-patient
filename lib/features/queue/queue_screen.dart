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

class _QueueScreenState extends State<QueueScreen> with SingleTickerProviderStateMixin {
  int _currentPosition = 0;
  int _estimatedWaitTime = 0;
  String _ticketNumber = '--';
  final QueueSocket _socket = QueueSocket();
  bool _isConnected = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
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
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isConnected) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [AppTheme.slateLight, Colors.white],
          ),
        ),
        child: Center(
          child: GlassContainer(
            blur: 15,
            opacity: isDark ? 0.1 : 0.6,
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Text(
                  "Aucun ticket actif",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  "Scannez le QR Code à l'hôpital\nou prenez un rendez-vous.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, height: 1.5),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.get('queue'),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Carte Principale (Ticket) — Premium Glass
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final glowOpacity = 0.15 + (_pulseController.value * 0.15);
                    return GlassContainer(
                      blur: 28,
                      opacity: isDark ? 0.1 : 0.7,
                      border: Border.all(
                        color: AppTheme.primaryTeal.withOpacity(0.3 + _pulseController.value * 0.1),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            loc.get('your_number'),
                            style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.black45),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryTeal.withOpacity(glowOpacity),
                                  blurRadius: 40,
                                  spreadRadius: -10,
                                ),
                              ],
                            ),
                            child: Text(
                              _ticketNumber,
                              style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryTeal,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn(
                                _currentPosition.toString(), 
                                loc.get('people_waiting'),
                                AppTheme.warning
                              ),
                              Container(
                                height: 60,
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
                              _buildStatColumn(
                                '$_estimatedWaitTime min', 
                                loc.get('estimated_time'),
                                AppTheme.success
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const Spacer(),
                
                if (_currentPosition <= 2 && _currentPosition > 0)
                  GlassContainer(
                    blur: 12,
                    opacity: isDark ? 0.08 : 0.5,
                    border: Border.all(color: AppTheme.danger.withOpacity(0.4), width: 1.5),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            loc.get('prepare_id'),
                            style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                if (_currentPosition == 0)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.success, AppTheme.primaryTeal],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.success.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: -5,
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "C'est votre tour !\nVeuillez vous diriger vers le bureau.",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.withOpacity(0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

