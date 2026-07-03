import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/localization/app_localizations.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/widgets/glass_container.dart';
import 'package:queuecare_patient/features/queue/queue_screen.dart';
import 'package:queuecare_patient/features/pharmacy/pharmacy_screen.dart';
import 'package:queuecare_patient/features/settings/settings_screen.dart';
import 'package:queuecare_patient/features/appointments/appointments_screen.dart';
import 'package:queuecare_patient/features/prescriptions/prescriptions_screen.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'package:queuecare_patient/core/database/local_database.dart';
import 'package:queuecare_patient/core/utils/qr_scanner_utils.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  const HomeScreen({super.key, this.isGuest = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;

  late final List<Widget> _pages;
  late AnimationController _bgAnimController;
  late AnimationController _cardAnimController;
  late Animation<double> _cardStaggerAnimation;

  @override
  void initState() {
    super.initState();
    
    // Subtle background animation
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Card entrance animation
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _cardStaggerAnimation = CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOutCubic,
    );
    _cardAnimController.forward();

    _pages = [
      _buildDashboard(),
      const QueueScreen(),
      const PharmacyScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _cardAnimController.dispose();
    super.dispose();
  }

  void _showQRScanner(BuildContext context) {
    QRScannerUtils.showQRScannerDialog(
      context,
      onTicketScanned: (ticket) {
        setState(() {
          _pages[1] = QueueScreen(key: UniqueKey(), initialTicket: ticket);
          _currentIndex = 1;
        });
      },
    );
  }

  Widget _buildDashboard() {
    return Builder(
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Row(
              children: [
                // Logo QueueCare
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/queuecare_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'QueueCare',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: isDark ? Colors.white : AppTheme.slateDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryTeal.withOpacity(0.15),
                      AppTheme.primaryTeal.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryTeal.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_outlined),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? AppTheme.slateDark : Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.notifications_active_outlined, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Aucune nouvelle notification pour le moment.'),
                          ],
                        ),
                        backgroundColor: isDark ? AppTheme.slateDark : AppTheme.primaryTeal,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  color: AppTheme.primaryTeal,
                ),
              )
            ],
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
                            Color.lerp(const Color(0xFF0F172A), const Color(0xFF0D3B35), _bgAnimController.value * 0.3)!,
                            const Color(0xFF0A0F1E),
                          ]
                        : [
                            const Color(0xFFF0FDFA), // teal-50
                            Colors.white,
                            Color.lerp(Colors.white, const Color(0xFFE0F2FE), _bgAnimController.value * 0.5)!, // sky-100
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    
                    // Greeting section with subtle animation
                    AnimatedBuilder(
                      animation: _cardStaggerAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _cardStaggerAnimation.value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - _cardStaggerAnimation.value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isGuest ? loc.get('occasional_patient') : loc.get('welcome_back'),
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 28,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Que souhaitez-vous faire aujourd\'hui ?',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // Action cards grid
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Ajustement dynamique du ratio pour s'adapter à tous les mobiles
                          double aspectRatio = constraints.maxWidth / (constraints.maxHeight * 1.1);
                          if (aspectRatio < 0.6) aspectRatio = 0.6;
                          if (aspectRatio > 1.2) aspectRatio = 1.2;
                          
                          int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                          if (constraints.maxWidth < 320) crossAxisCount = 1;

                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: crossAxisCount == 1 ? 2.5 : aspectRatio,
                            padding: const EdgeInsets.only(bottom: 120),
                        children: [
                          _buildPremiumActionCard(
                            context,
                            title: loc.get('queue'),
                            subtitle: 'Suivre votre position',
                            imagePath: 'assets/images/queue_illustration.png',
                            color: AppTheme.primaryTeal,
                            gradientColors: [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
                            delay: 0,
                            onTap: () => setState(() => _currentIndex = 1),
                          ),
                          _buildPremiumActionCard(
                            context,
                            title: loc.get('pharmacy'),
                            subtitle: 'Trouver une pharmacie',
                            imagePath: 'assets/images/pharmacy_illustration.png',
                            color: AppTheme.success,
                            gradientColors: [const Color(0xFF059669), const Color(0xFF10B981)],
                            delay: 1,
                            onTap: () => setState(() => _currentIndex = 2),
                          ),
                            if (!widget.isGuest)
                              _buildPremiumActionCard(
                                context,
                                title: 'Ordonnances',
                                subtitle: 'Vos prescriptions',
                                imagePath: 'assets/images/prescription_illustration.png',
                                color: AppTheme.warning,
                                gradientColors: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
                                delay: 2,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const PrescriptionsScreen()),
                                  );
                                },
                              ),
                          _buildPremiumActionCard(
                            context,
                            title: loc.get('settings'),
                            subtitle: 'Préférences',
                            imagePath: 'assets/images/settings_illustration.png',
                            color: AppTheme.accentPurple,
                            gradientColors: [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
                            delay: 3,
                            onTap: () => setState(() => _currentIndex = 3),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
                ),
              ),
            ),
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryTeal.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _showQRScanner(context),
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text('Scanner QR', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              backgroundColor: AppTheme.primaryTeal,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        );
      }
    );
  }

  Widget _buildPremiumActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String imagePath,
    required Color color,
    required List<Color> gradientColors,
    required int delay,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _cardStaggerAnimation,
      builder: (context, child) {
        final delayedValue = ((_cardStaggerAnimation.value - delay * 0.15).clamp(0.0, 1.0) / (1.0 - delay * 0.15).clamp(0.01, 1.0)).clamp(0.0, 1.0);
        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - delayedValue)),
            child: Transform.scale(
              scale: 0.8 + 0.2 * delayedValue,
              child: child,
            ),
          ),
        );
      },
      child: _PremiumCardContent(
        title: title,
        subtitle: subtitle,
        imagePath: imagePath,
        color: color,
        gradientColors: gradientColors,
        isDark: isDark,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBody: true, // Pour que le fond glisse sous la navigation
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          // Floating Glass Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20, 
                right: 20, 
                bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 20,
                top: 10,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF0F172A).withOpacity(0.6) 
                          : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isDark 
                            ? Colors.white.withOpacity(0.1) 
                            : Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 24,
                          spreadRadius: -4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.home_outlined, Icons.home, loc.get('home'), isDark),
                        _buildNavItem(1, Icons.confirmation_number_outlined, Icons.confirmation_number, loc.get('queue'), isDark),
                        _buildNavItem(2, Icons.local_pharmacy_outlined, Icons.local_pharmacy, loc.get('pharmacy'), isDark),
                        _buildNavItem(3, Icons.settings_outlined, Icons.settings, loc.get('settings'), isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryTeal.withOpacity(0.12) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSelected ? iconFilled : iconOutlined,
                key: ValueKey<bool>(isSelected),
                color: isSelected 
                    ? AppTheme.primaryTeal 
                    : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                size: 24,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// Separate StatefulWidget for hover/tap animation on cards
class _PremiumCardContent extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color color;
  final List<Color> gradientColors;
  final bool isDark;
  final VoidCallback onTap;

  const _PremiumCardContent({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.color,
    required this.gradientColors,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_PremiumCardContent> createState() => _PremiumCardContentState();
}

class _PremiumCardContentState extends State<_PremiumCardContent> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _pressController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _pressController.reverse();
      },
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - _pressController.value * 0.04,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border.all(
              color: widget.color.withOpacity(widget.isDark ? 0.2 : 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(widget.isDark ? 0.15 : 0.12),
                blurRadius: 24,
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
              if (!widget.isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  spreadRadius: -4,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Subtle gradient accent at top
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.color.withOpacity(0.15),
                          widget.color.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Image illustration
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.color.withOpacity(0.08),
                              widget.color.withOpacity(0.15),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withOpacity(0.2),
                              blurRadius: 16,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              widget.imagePath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // Title
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: widget.isDark ? Colors.white : AppTheme.slateDark,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      
                      // Subtitle
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: widget.isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Mini action indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: widget.gradientColors),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: -3,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ouvrir',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
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
}
