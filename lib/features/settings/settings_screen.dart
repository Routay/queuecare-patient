import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queuecare_patient/core/localization/app_localizations.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/features/auth/auth_screen.dart';
import 'package:queuecare_patient/core/bloc/settings_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  late AnimationController _bgAnimController;
  late AnimationController _entranceAnimController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _entranceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _entranceAnimController.forward();
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _entranceAnimController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredChild(int index, Widget child) {
    return AnimatedBuilder(
      animation: _entranceAnimController,
      builder: (context, c) {
        final delay = index * 0.1;
        final progress = ((_entranceAnimController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - progress)),
            child: c,
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
                        Color.lerp(const Color(0xFF0F172A), const Color(0xFF1A1040), _bgAnimController.value * 0.3)!,
                        const Color(0xFF0A0F1E),
                      ]
                    : [
                        const Color(0xFFF0FDFA),
                        Colors.white,
                        Color.lerp(Colors.white, const Color(0xFFF3E8FF), _bgAnimController.value * 0.4)!,
                        const Color(0xFFF8FAFC),
                      ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Header
                  _buildStaggeredChild(0, Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Image.asset(
                          'assets/images/settings_illustration.png',
                          width: 28,
                          height: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.get('settings'),
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 26,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Gérez vos préférences',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),

                  const SizedBox(height: 28),

                  // User Profile Section
                  _buildStaggeredChild(1, Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentPurple.withOpacity(0.35),
                          blurRadius: 24,
                          spreadRadius: -6,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative circle
                        Positioned(
                          top: -20,
                          right: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                              ),
                              child: const Icon(Icons.person_rounded, size: 32, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Patient Connecté',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Gérez vos préférences',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 32),
                  
                  _buildStaggeredChild(2, Text(
                    'GÉNÉRAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  )),
                  const SizedBox(height: 12),
                  
                  _buildStaggeredChild(3, Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          spreadRadius: -2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          title: '${loc.get('language')} (FR / Wolof)',
                          subtitle: 'Changer la langue de l\'application',
                          value: state.locale.languageCode == 'wo',
                          onChanged: (_) => context.read<SettingsCubit>().toggleLanguage(),
                          isDark: isDark,
                        ),
                        Divider(height: 1, indent: 64, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        _buildSettingTile(
                          icon: Icons.dark_mode_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          title: loc.get('dark_mode'),
                          subtitle: 'Thème sombre pour le confort visuel',
                          value: state.themeMode == ThemeMode.dark,
                          onChanged: (_) => context.read<SettingsCubit>().toggleTheme(),
                          isDark: isDark,
                        ),
                        Divider(height: 1, indent: 64, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        _buildSettingTile(
                          icon: Icons.accessibility_new_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          title: loc.get('simplified_mode'),
                          subtitle: 'Affichage agrandi et contrasté',
                          value: state.isSimplifiedMode,
                          onChanged: (_) => context.read<SettingsCubit>().toggleSimplifiedMode(),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 32),
                  
                  _buildStaggeredChild(4, Text(
                    'À PROPOS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  )),
                  const SizedBox(height: 12),
                  
                  _buildStaggeredChild(5, Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          spreadRadius: -2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryTeal, size: 22),
                          ),
                          title: Text('Version', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.slateDark)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '1.0.0',
                              style: TextStyle(
                                color: AppTheme.primaryTeal,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Divider(height: 1, indent: 64, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 22),
                          ),
                          title: Text('Confidentialité', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.slateDark)),
                          trailing: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),
                  )),

                  const SizedBox(height: 48),
                  
                  // Logout button
                  _buildStaggeredChild(6, Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.danger,
                          AppTheme.danger.withOpacity(0.85),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.danger.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: -6,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.danger.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Déconnexion',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppTheme.slateDark,
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                'Êtes-vous sûr de vouloir vous déconnecter de votre compte QueueCare ?',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  height: 1.5,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    'Annuler',
                                    style: TextStyle(
                                      color: isDark ? Colors.white54 : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.danger.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: -4,
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.of(context, rootNavigator: true).pushReplacement(
                                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.danger,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                    child: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout_rounded, size: 20, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(
                                loc.get('logout'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),
                  
                  // Bottom padding for navigation bar
                  const SizedBox(height: 100),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDark ? Colors.white : AppTheme.slateDark,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.primaryTeal.withOpacity(0.5),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppTheme.primaryTeal;
          return isDark ? Colors.white38 : Colors.grey[400];
        }),
      ),
    );
  }
}
