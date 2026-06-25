import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/localization/app_localizations.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/network/queue_socket.dart';

class QueueScreen extends StatefulWidget {
  final Map<String, dynamic>? initialTicket;
  const QueueScreen({super.key, this.initialTicket});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  int _currentPosition = 0;
  int _estimatedWaitTime = 0;
  String _ticketNumber = '--';
  final QueueSocket _socket = QueueSocket();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
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
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "Vous n'avez pas de ticket actif.",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              "Allez sur l'accueil pour prendre un rendez-vous\nou scannez le QR Code à l'hôpital.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            )
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.slateDark : AppTheme.slateLight,
      body: SafeArea(
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
              const SizedBox(height: 40),
              
              // Carte Principale (Ticket)
              Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        loc.get('your_number'),
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _ticketNumber,
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryTeal,
                          letterSpacing: 2,
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
                            color: Colors.grey.withOpacity(0.3),
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
                ),
              ),
              
              const Spacer(),
              
              if (_currentPosition <= 2 && _currentPosition > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.danger.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          loc.get('prepare_id'),
                          style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                
              if (_currentPosition == 0)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      "C'est votre tour ! Veuillez vous diriger vers le bureau.",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
