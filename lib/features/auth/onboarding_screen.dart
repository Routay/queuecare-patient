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

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _bgAnimController;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Gagnez du temps",
      "description": "Prenez un ticket virtuel pour l'hôpital depuis chez vous et suivez la file d'attente en temps réel.",
      "image": "assets/images/queue_illustration.png",
      "color": AppTheme.primaryTeal,
      "gradientColors": [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
    },
    {
      "title": "Trouvez vos médicaments",
      "description": "Fini l'errance pharmaceutique. Géolocalisez les pharmacies de garde et vérifiez la disponibilité de vos prescriptions.",
      "image": "assets/images/pharmacy_logo.png",
      "color": AppTheme.success,
      "gradientColors": [const Color(0xFF059669), const Color(0xFF10B981)],
    },
    {
      "title": "La santé pour tous",
      "description": "Accessible et intuitif, avec un mode simplifié pour garantir que personne ne soit laissé pour compte.",
      "image": "assets/images/onboarding_medical.png",
      "color": AppTheme.accentPurple,
      "gradientColors": [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
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
              );
            },
          ),
          
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Passer',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3),
                      ),
                    ),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Glassmorphism image container
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: _onboardingData[index]['color'].withOpacity(0.2),
                                    blurRadius: 40,
                                    spreadRadius: -10,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: GlassContainer(
                                blur: 20,
                                opacity: isDark ? 0.1 : 0.6,
                                padding: const EdgeInsets.all(32),
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: _onboardingData[index]['color'].withOpacity(0.3),
                                  width: 1.5,
                                ),
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        _onboardingData[index]['color'].withOpacity(0.1),
                                        _onboardingData[index]['color'].withOpacity(0.2),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _onboardingData[index]['color'].withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: -5,
                                      )
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Image.asset(
                                        _onboardingData[index]['image'],
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 56),
                            Text(
                              _onboardingData[index]['title'],
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 32,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                _onboardingData[index]['description'],
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  height: 1.6,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
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
                      // Smooth dot indicators
                      Row(
                        children: List.generate(
                          _onboardingData.length,
                          (index) {
                            final isActive = _currentPage == index;
                            final activeColor = _onboardingData[_currentPage]['color'] as Color;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.only(right: 8),
                              height: 8,
                              width: isActive ? 28 : 8,
                              decoration: BoxDecoration(
                                color: isActive 
                                  ? activeColor 
                                  : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Next/Start Button
                      _currentPage == _onboardingData.length - 1
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _onboardingData[_currentPage]['color'].withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: -4,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _completeOnboarding,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                backgroundColor: _onboardingData[_currentPage]['color'],
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text(
                                'Commencer',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _onboardingData[_currentPage]['color'].withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: -4,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: FloatingActionButton(
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              backgroundColor: _onboardingData[_currentPage]['color'],
                              elevation: 0,
                              shape: const CircleBorder(),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 28),
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
    );
  }
}
