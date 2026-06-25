import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queuecare_patient/core/localization/app_localizations.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/features/auth/auth_screen.dart';
import 'package:queuecare_patient/core/bloc/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language, color: AppTheme.primaryTeal),
                    title: Text(loc.get('language') + ' (FR / Wolof)'),
                    trailing: Switch(
                      value: state.locale.languageCode == 'wo',
                      onChanged: (_) {
                        context.read<SettingsCubit>().toggleLanguage();
                      },
                      activeColor: AppTheme.primaryTeal,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dark_mode, color: AppTheme.primaryTeal),
                    title: Text(loc.get('dark_mode')),
                    trailing: Switch(
                      value: state.themeMode == ThemeMode.dark,
                      onChanged: (_) {
                        context.read<SettingsCubit>().toggleTheme();
                      },
                      activeColor: AppTheme.primaryTeal,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.accessibility_new, color: AppTheme.primaryTeal),
                    title: Text(loc.get('simplified_mode')),
                    trailing: Switch(
                      value: state.isSimplifiedMode,
                      onChanged: (_) {
                        context.read<SettingsCubit>().toggleSimplifiedMode();
                      },
                      activeColor: AppTheme.primaryTeal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
              icon: const Icon(Icons.logout),
              label: Text(loc.get('logout')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
              ),
            ),
          ],
        );
      },
    );
  }
}
