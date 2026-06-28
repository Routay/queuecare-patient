import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/features/auth/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:queuecare_patient/core/widgets/glass_container.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _bgAnimController;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Gagnez du temps",
      "description": "Prenez un ticket virtuel pour l'hôpital depuis chez vous et suivez la file d'attente en temps réel.",
      "icon": Icons.timer_outlined,
      "color": AppTheme.primaryLight,
    },
    {
      "title": "Trouvez vos médicaments",
      "description": "Fini l'errance pharmaceutique. Géolocalisez les pharmacies de garde et vérifiez la disponibilité de vos prescriptions.",
      "icon": Icons.medical_services_outlined,
      "color": AppTheme.accentPurple,
    },
    {
      "title": "Accessible à tous",
      "description": "Disponible en Français et en Wolof, avec un mode simplifié pour garantir que personne ne soit laissé pour compte.",
      "icon": Icons.accessibility_new,
      "color": AppTheme.warning,
    },
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background animé premium
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      Color.lerp(
                        AppTheme.primaryTeal.withOpacity(isDark ? 0.2 : 0.1),
                        AppTheme.accentPurple.withOpacity(isDark ? 0.2 : 0.1),
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
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text('Passer', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(32.0),
                          blur: 20,
                          opacity: isDark ? 0.1 : 0.6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: _onboardingData[index]['color'].withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _onboardingData[index]['color'].withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: -5,
                                    )
                                  ],
                                ),
                                child: Icon(
                                  _onboardingData[index]['icon'],
                                  size: 100,
                                  color: _onboardingData[index]['color'],
                                ),
                              ),
                              const SizedBox(height: 64),
                              Text(
                                _onboardingData[index]['title'],
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _onboardingData[index]['description'],
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _onboardingData.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index 
                                ? AppTheme.primaryTeal 
                                : AppTheme.primaryTeal.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      _currentPage == _onboardingData.length - 1
                        ? ElevatedButton(
                            onPressed: _completeOnboarding,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                            child: const Text('Commencer'),
                          )
                        : FloatingActionButton(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            backgroundColor: AppTheme.primaryTeal,
                            elevation: 8,
                            child: const Icon(Icons.arrow_forward, color: Colors.white),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
