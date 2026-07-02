import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'package:queuecare_patient/core/database/local_database.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _prescriptions = [];
  String? _error;
  late AnimationController _bgAnimController;
  late AnimationController _listAnimController;

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
    
    _fetchPrescriptions();
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrescriptions() async {
    try {
      setState(() { _isLoading = true; _error = null; });
      
      // Get active ticket
      final ticket = await LocalDatabase.instance.getActiveTicket();
      if (ticket == null || ticket['id'] == null) {
        setState(() {
          _isLoading = false;
          _error = "Aucun ticket actif. Impossible de trouver vos ordonnances.";
        });
        return;
      }

      final String ticketId = ticket['id'].toString();
      
      // Fetch prescriptions from backend
      final response = await ApiClient().dio.get('/consultations/prescriptions/patient/$ticketId');
      
      if (mounted) {
        setState(() {
          _prescriptions = response.data;
          _isLoading = false;
        });
        _listAnimController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Erreur lors de la récupération des ordonnances : $e";
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return "${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Mes Ordonnances',
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
                        Color.lerp(const Color(0xFF0F172A), const Color(0xFF3B2E05), _bgAnimController.value * 0.3)!, // Subtle dark amber
                        const Color(0xFF0A0F1E),
                      ]
                    : [
                        const Color(0xFFFFFBEB), // amber-50
                        Colors.white,
                        Color.lerp(Colors.white, const Color(0xFFFEF3C7), _bgAnimController.value * 0.4)!, // amber-100
                        const Color(0xFFF8FAFC),
                      ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: _isLoading
              ? _buildShimmerLoading(isDark)
              : _error != null
                  ? _buildErrorState(isDark)
                  : _prescriptions.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildPrescriptionsList(isDark),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.danger),
            ),
            const SizedBox(height: 24),
            Text(
              "Erreur de connexion",
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.slateDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, 
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchPrescriptions,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.warning.withOpacity(0.08),
                    AppTheme.warning.withOpacity(0.15),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warning.withOpacity(0.1),
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
                    'assets/images/prescription_illustration.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Aucune ordonnance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Les ordonnances prescrites lors de vos\nconsultations s\'afficheront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[300]!,
          highlightColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionsList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _fetchPrescriptions,
      color: AppTheme.warning,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _prescriptions.length,
        itemBuilder: (context, index) {
          final p = _prescriptions[index];
          final isDelivered = p['status'] == 'delivered';

          return AnimatedBuilder(
            animation: _listAnimController,
            builder: (context, child) {
              final delay = index * 0.15;
              final progress = ((_listAnimController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
              return Opacity(
                opacity: progress,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - progress)),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Accent gradient on the left edge
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isDelivered ? AppTheme.success : AppTheme.warning,
                            (isDelivered ? AppTheme.success : AppTheme.warning).withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Doctor & Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.medical_services_outlined, color: AppTheme.warning, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Dr. ${p['doctorName']}',
                                          style: TextStyle(
                                            fontSize: 16, 
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : AppTheme.slateDark,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatDate(p['date']),
                                          style: TextStyle(
                                            fontSize: 12, 
                                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDelivered ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isDelivered ? 'Délivrée' : 'En attente',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDelivered ? AppTheme.success : AppTheme.warning,
                                ),
                              ),
                            )
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        const SizedBox(height: 20),
                        
                        // Prescription details
                        Text(
                          'Médicaments prescrits',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        ...(p['medicines'] as List).map((m) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            m['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: isDark ? Colors.white : AppTheme.slateDark,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.slateDark.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'x${m['quantity']}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: isDark ? Colors.white70 : AppTheme.slateDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (m['dosage'] != null && m['dosage'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        m['dosage'],
                                        style: TextStyle(
                                          fontSize: 12, 
                                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              )
                            ],
                          ),
                        )),
                        
                        if (p['notes'] != null && p['notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.warning.withOpacity(0.1)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.warning.withOpacity(0.8)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p['notes'],
                                    style: TextStyle(
                                      fontSize: 13, 
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                        
                        if (isDelivered) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.success),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Délivrée par ${p['deliveredBy']} à la pharmacie.',
                                  style: const TextStyle(
                                    fontSize: 12, 
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ));
        },
      ),
    );
  }
}
