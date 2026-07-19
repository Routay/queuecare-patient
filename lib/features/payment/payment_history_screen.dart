import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'package:queuecare_patient/core/widgets/shimmer_loading.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String patientPhone;

  const PaymentHistoryScreen({super.key, required this.patientPhone});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _receipts = [];
  int _totalSpent = 0;
  int _totalTransactions = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient()
          .dio
          .get('/payments/history/${widget.patientPhone}');
      final data = response.data;
      if (mounted) {
        setState(() {
          _receipts = data['data'] ?? [];
          _totalSpent = data['totalSpentFCFA'] ?? 0;
          _totalTransactions = data['totalTransactions'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger l\'historique. Vérifiez votre connexion.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '—';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy, HH:mm', 'fr_FR').format(date);
    } catch (e) {
      return isoString.split('T').first;
    }
  }

  Color _operatorColor(String? operator) {
    switch (operator) {
      case 'Wave':
        return Colors.lightBlue;
      case 'Orange Money':
        return Colors.deepOrange;
      default:
        return AppTheme.primaryTeal;
    }
  }

  IconData _operatorIcon(String? operator) {
    switch (operator) {
      case 'Wave':
        return Icons.waves;
      case 'Orange Money':
        return Icons.monetization_on;
      default:
        return Icons.payment;
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'ticket':
        return Icons.confirmation_number_outlined;
      case 'appointment':
        return Icons.calendar_today_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Historique des Paiements'),
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
              ? _buildShimmerList(isDark)
              : _error != null
                  ? _buildError()
                  : RefreshIndicator(
                      onRefresh: _fetchHistory,
                      color: AppTheme.primaryTeal,
                      child: _receipts.isEmpty
                          ? _buildEmptyState(isDark)
                          : _buildContent(isDark),
                    ),
        ),
      ),
    );
  }

  Widget _buildShimmerList(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary shimmer
        ShimmerLoading(width: double.infinity, height: 100, isDark: isDark, borderRadius: 20),
        const SizedBox(height: 24),
        ...List.generate(5, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerLoading(width: double.infinity, height: 90, isDark: isDark, borderRadius: 16),
        )),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Icon(Icons.receipt_long, size: 72, color: Colors.grey),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Aucun paiement effectué.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Vos reçus apparaîtront ici après votre premier paiement.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // ── Carte résumé ──
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryTeal, AppTheme.primaryTeal.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppTheme.primaryTeal.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total dépensé', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalSpent FCFA',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$_totalTransactions', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text('transaction(s)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),

        // ── Liste des reçus ──
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Reçus récents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        ..._receipts.map((r) => _buildReceiptCard(r, isDark)),
      ],
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> r, bool isDark) {
    final opColor = _operatorColor(r['operator']);
    final amount = r['amount'] ?? 0;
    final type = r['type'] ?? 'ticket';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Icône opérateur
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: opColor.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(_operatorIcon(r['operator']), color: opColor, size: 22),
          ),
          const SizedBox(width: 14),
          // Détails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_typeIcon(type), size: 14, color: isDark ? Colors.white54 : Colors.black45),
                    const SizedBox(width: 4),
                    Text(
                      type == 'ticket' ? 'Ticket de file' : 'Rendez-vous',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${r['operator']} • ${_formatDate(r['date'])}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                ),
              ],
            ),
          ),
          // Montant
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amount FCFA',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: opColor),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Payé', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
