import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/localization/app_localizations.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/network/queue_socket.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'package:queuecare_patient/core/database/local_database.dart';
import 'package:queuecare_patient/core/widgets/glass_container.dart';
import 'package:queuecare_patient/core/utils/qr_scanner_utils.dart';
import 'package:queuecare_patient/core/services/notification_service.dart';

class QueueScreen extends StatefulWidget {
  final Map<String, dynamic>? initialTicket;
  const QueueScreen({super.key, this.initialTicket});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> with TickerProviderStateMixin {
  // Position commence à 1 (1 = premier, 2 = deuxième, etc.)
  int _currentPosition = 1;
  int _estimatedWaitTime = 0;
  String _ticketNumber = '--';
  String? _ticketId;
  final QueueSocket _socket = QueueSocket();
  bool _isConnected = false;
  bool _isPostponing = false;
  late AnimationController _pulseController;
  late AnimationController _bgWaveController;
  late AnimationController _numberAnimController;

  @override
  void initState() {
    super.initState();
    
    // Demander la permission pour les notifications
    NotificationService.instance.requestPermission();
    
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
    } else {
      _loadTicketFromDb();
    }
  }

  Future<void> _loadTicketFromDb() async {
    final ticket = await LocalDatabase.instance.getActiveTicket();
    if (ticket != null) {
      _setupFromTicket(ticket);
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
      // Position commence à 1: le serveur renvoie 0 = c'est votre tour, 1 = 1er en attente
      // On affiche position + 1 pour que l'affichage commence à 1
      final rawPosition = ticket['position'] ?? 0;
      _currentPosition = rawPosition + 1; // 1-indexed display
      _estimatedWaitTime = ticket['estimatedWaitTime'] ?? 0;
      _ticketId = ticket['id']?.toString();
      _isConnected = true;
    });
    _numberAnimController.forward(from: 0);

    final ticketId = ticket['id'];
    if (ticketId != null) {
      _socket.connect(ticketId.toString());
      _socket.stream.listen((data) {
        if (mounted && data['type'] == 'queue_update') {
          final rawNewPosition = data['position'] ?? 0;
          final newPosition = rawNewPosition + 1; // 1-indexed display
          
          // Notifications quand c'est bientôt le tour
          if (newPosition <= 2 && _currentPosition > 2) {
            NotificationService.instance.showNotification(
              "Bientôt votre tour !", 
              "Préparez-vous, vous êtes en ${newPosition == 1 ? '1ère' : '2ème'} position."
            );
          }
          // Notification quand c'est le tour (position serveur = 0, display = 1)
          if (rawNewPosition == 0 && (_currentPosition - 1) > 0) {
            NotificationService.instance.showNotification(
              "C'est votre tour !", 
              "Veuillez vous diriger vers le bureau."
            );
          }

          setState(() {
            _currentPosition = newPosition;
            _estimatedWaitTime = data['estimatedWaitTime'] ?? 0;
          });
        }
      });
    }
  }

  /// Reporter son passage : déplace le patient en dernière position
  Future<void> _postponeTicket(AppLocalizations loc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.get('postpone_title')),
        content: Text(loc.get('postpone_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.get('cancel_button')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.get('confirm_postpone')),
          ),
        ],
      ),
    );
    
    if (confirm != true || _ticketId == null) return;
    
    setState(() => _isPostponing = true);
    
    try {
      // Appel API pour repousser le ticket à la dernière position
      final response = await ApiClient().dio.post(
        '/queue/ticket/$_ticketId/postpone',
      );
      
      if (mounted) {
        if (response.statusCode == 200) {
          final data = response.data;
          setState(() {
            final rawPosition = data['position'] ?? (_currentPosition - 1);
            _currentPosition = rawPosition + 1;
            _estimatedWaitTime = data['estimatedWaitTime'] ?? _estimatedWaitTime;
            _isPostponing = false;
          });
          
          // Mettre à jour la DB locale
          await LocalDatabase.instance.saveActiveTicket({
            'id': _ticketId,
            'ticketNumber': _ticketNumber,
            'position': _currentPosition - 1,
            'estimatedWaitTime': _estimatedWaitTime,
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.get('postpone_success')),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPostponing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.get('postpone_error')),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  /// Annuler le ticket et quitter la file
  Future<void> _leaveQueue(AppLocalizations loc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.get('leave_queue_title')),
        content: Text(loc.get('leave_queue_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.get('cancel_button')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.get('confirm_leave')),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await LocalDatabase.instance.clearTicket();
      _socket.disconnect();
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
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

    // Position serveur 0 = c'est votre tour (display position 1)
    final isYourTurn = (_currentPosition - 1) == 0;

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
          child: SingleChildScrollView(
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
                          loc.get('realtime_tracking'),
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

                            // Stats row — Position commence à 1
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatCard(
                                  _currentPosition.toString(), 
                                  loc.get('position_label'),
                                  isYourTurn ? AppTheme.success : AppTheme.warning,
                                  Icons.format_list_numbered,
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
                                  '${_estimatedWaitTime} ${loc.get('minutes')}', 
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
                
                const SizedBox(height: 24),
                
                // Alert: prepare ID (position 1 ou 2)
                if (_currentPosition <= 2 && !isYourTurn)
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
                  
                // Your turn banner (position serveur == 0, display == 1)
                if (isYourTurn)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.get('your_turn'),
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.w800, 
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.get('your_turn_subtitle'),
                                style: const TextStyle(
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
                
                const SizedBox(height: 8),
                
                // --- Action Buttons ---
                // Bouton Reporter mon passage (orange)
                if (!isYourTurn)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: TextButton.icon(
                      onPressed: _isPostponing ? null : () => _postponeTicket(loc),
                      icon: _isPostponing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.warning))
                        : const Icon(Icons.low_priority_rounded, color: AppTheme.warning, size: 20),
                      label: Text(
                        loc.get('postpone'), 
                        style: TextStyle(
                          color: _isPostponing ? AppTheme.warning.withOpacity(0.5) : AppTheme.warning, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: AppTheme.warning.withOpacity(0.06),
                      ),
                    ),
                  ),
                
                // Bouton Quitter la file (rouge)
                TextButton.icon(
                  onPressed: () => _leaveQueue(loc),
                  icon: const Icon(Icons.exit_to_app_rounded, color: AppTheme.danger, size: 20),
                  label: Text(
                    loc.get('leave_queue'), 
                    style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: AppTheme.danger.withOpacity(0.05),
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
                loc.get('no_active_ticket'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                loc.get('scan_qr_prompt'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  height: 1.6,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  QRScannerUtils.showQRScannerDialog(
                    context,
                    onTicketScanned: (ticket) {
                      _setupFromTicket(ticket);
                    },
                  );
                },
                child: Container(
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
                        loc.get('scan_qr_button'),
                        style: TextStyle(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
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
