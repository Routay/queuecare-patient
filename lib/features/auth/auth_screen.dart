import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/localization/app_localizations.dart';
import 'package:queuecare_patient/features/home/home_screen.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/widgets/glass_container.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _bgAnimController;
  late AnimationController _entranceAnimController;
  late Animation<double> _logoAnimation;
  late Animation<double> _titleAnimation;
  late Animation<double> _formAnimation;
  late Animation<double> _dividerAnimation;
  late Animation<double> _guestAnimation;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _entranceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Staggered entrance animations
    _logoAnimation = CurvedAnimation(
      parent: _entranceAnimController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
    );
    _titleAnimation = CurvedAnimation(
      parent: _entranceAnimController,
      curve: const Interval(0.15, 0.45, curve: Curves.easeOutCubic),
    );
    _formAnimation = CurvedAnimation(
      parent: _entranceAnimController,
      curve: const Interval(0.30, 0.70, curve: Curves.easeOutCubic),
    );
    _dividerAnimation = CurvedAnimation(
      parent: _entranceAnimController,
      curve: const Interval(0.55, 0.80, curve: Curves.easeOutCubic),
    );
    _guestAnimation = CurvedAnimation(
      parent: _entranceAnimController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
    );

    _entranceAnimController.forward();
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _entranceAnimController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _guestLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(isGuest: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildAnimatedChild({
    required Animation<double> animation,
    required Widget child,
    double slideOffset = 30,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, slideOffset * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Animated premium background
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      isDark ? const Color(0xFF0F172A) : AppTheme.slateLight,
                      Color.lerp(
                        AppTheme.primaryTeal.withOpacity(isDark ? 0.2 : 0.1),
                        AppTheme.accentPurple.withOpacity(isDark ? 0.15 : 0.08),
                        _bgAnimController.value,
                      )!,
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Decorative floating orbs
          Positioned(
            top: -80,
            right: -40,
            child: AnimatedBuilder(
              animation: _bgAnimController,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(
                    _bgAnimController.value * 20,
                    _bgAnimController.value * 15,
                  ),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryTeal.withOpacity(isDark ? 0.08 : 0.06),
                          AppTheme.primaryTeal.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: AnimatedBuilder(
              animation: _bgAnimController,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(
                    -_bgAnimController.value * 15,
                    -_bgAnimController.value * 10,
                  ),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentPurple.withOpacity(isDark ? 0.08 : 0.05),
                          AppTheme.accentPurple.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo with glow + bounce
                    _buildAnimatedChild(
                      animation: _logoAnimation,
                      slideOffset: 40,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withOpacity(0.15),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryTeal.withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: -10,
                            )
                          ]
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/queuecare_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Animated Title
                    _buildAnimatedChild(
                      animation: _titleAnimation,
                      slideOffset: 25,
                      child: Column(
                        children: [
                          Text(
                            loc.get('welcome'),
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Votre santé, simplifiée.',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),

                    // Animated Login Form with Glassmorphism
                    _buildAnimatedChild(
                      animation: _formAnimation,
                      slideOffset: 30,
                      child: GlassContainer(
                        blur: 24,
                        opacity: isDark ? 0.1 : 0.7,
                        padding: const EdgeInsets.all(32.0),
                        borderRadius: BorderRadius.circular(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryTeal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.verified_user_rounded, color: AppTheme.primaryTeal, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  loc.get('regular_patient'),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 20,
                                    color: isDark ? Colors.white : AppTheme.slateDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            // Phone field with icon
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                    blurRadius: 8,
                                    spreadRadius: -4,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'Numéro de téléphone',
                                  hintText: '+221 77 000 00 00',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  fillColor: isDark ? Colors.black26 : Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Password field with visibility toggle
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                    blurRadius: 8,
                                    spreadRadius: -4,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  fillColor: isDark ? Colors.black26 : Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                obscureText: _obscurePassword,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Forgot password link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryTeal,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                child: const Text(
                                  'Mot de passe oublié ?',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Login button with gradient and shadow
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryTeal.withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: -6,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoading ? null : _login,
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    child: Center(
                                      child: _isLoading 
                                        ? const SizedBox(
                                            width: 24, height: 24,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                loc.get('login'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                            ],
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Animated Divider
                    _buildAnimatedChild(
                      animation: _dividerAnimation,
                      slideOffset: 15,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.transparent,
                                  isDark ? Colors.white24 : Colors.black12,
                                ]),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                              ),
                              child: Text(
                                "OU",
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.black54,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  isDark ? Colors.white24 : Colors.black12,
                                  Colors.transparent,
                                ]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Animated Guest Button
                    _buildAnimatedChild(
                      animation: _guestAnimation,
                      slideOffset: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark 
                                ? Colors.white.withOpacity(0.1) 
                                : AppTheme.primaryTeal.withOpacity(0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                              blurRadius: 12,
                              spreadRadius: -4,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: _guestLogin,
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    color: isDark ? Colors.white70 : AppTheme.primaryTeal,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    loc.get('continue_guest'),
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : AppTheme.primaryTeal,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
