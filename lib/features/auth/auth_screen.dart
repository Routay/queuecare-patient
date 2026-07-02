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

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() => _isLoading = true);
    // Simulation de délai réseau
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _guestLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen(isGuest: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Arrière-plan animé premium
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
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo avec effet glow
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryTeal.withOpacity(0.3),
                            blurRadius: 30,
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
                    const SizedBox(height: 32),
                    Text(
                      loc.get('welcome'),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Formulaire Patient Régulier en Glassmorphism
                    GlassContainer(
                      blur: 24,
                      opacity: isDark ? 0.1 : 0.7,
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            loc.get('regular_patient'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              color: isDark ? Colors.white : AppTheme.slateDark,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Numéro de téléphone',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              fillColor: isDark ? Colors.black26 : Colors.white54,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline),
                              fillColor: isDark ? Colors.black26 : Colors.white54,
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(loc.get('login')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section Patient Occasionnel
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("OU", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    OutlinedButton.icon(
                      onPressed: _guestLogin,
                      icon: const Icon(Icons.person_outline),
                      label: Text(loc.get('continue_guest')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                        side: BorderSide(color: AppTheme.primaryTeal.withOpacity(0.5), width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: isDark ? Colors.white : AppTheme.primaryTeal,
                        backgroundColor: isDark ? Colors.black12 : Colors.white54,
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
