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

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  const HomeScreen({super.key, this.isGuest = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildDashboard(),
      const QueueScreen(),
      const PharmacyScreen(),
      const SettingsScreen(),
    ];
  }

  void _showQRScanner(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Faux fond de caméra
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black87,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 250, color: AppTheme.primaryTeal),
                  SizedBox(height: 32),
                  Text("Placez le code QR dans le cadre", style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            // Fermer
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            // Bouton Simulation
            Positioned(
              bottom: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Fermer la fausse caméra
                  Navigator.pop(ctx);
                  
                  // Récupérer les départements dynamiquement
                  List<String> departments = ["Consultation Générale", "Cardiologie", "Pédiatrie"];
                  try {
                    final deptsResponse = await ApiClient().dio.get('/queue/departments/list');
                    if (deptsResponse.data is List) {
                      departments = (deptsResponse.data as List).map((e) => e['name'].toString()).toList();
                    }
                  } catch (e) {
                    // Fallback on defaults
                  }

                  if (!context.mounted) return;

                  // Choisir le département
                  String? selectedDept = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        title: const Text('Choisir un service'),
                        children: departments.map((dept) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, dept),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(dept, style: const TextStyle(fontSize: 16))
                          ),
                        )).toList(),
                      );
                    }
                  );

                  if (selectedDept == null) return;

                  try {
                    // Appel réel à l'API pour générer un ticket
                    final response = await ApiClient().dio.post(
                      '/queue/ticket',
                      data: {'department': selectedDept}
                    );
                    
                    if (context.mounted) {
                      // Mettre à jour l'écran de file d'attente avec le vrai ticket
                      setState(() {
                        _pages[1] = QueueScreen(initialTicket: response.data);
                        _currentIndex = 1;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Code scanné ! Nouveau ticket généré pour $selectedDept.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la génération du ticket : $e'),
                          backgroundColor: AppTheme.danger,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Simuler Scan QR'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              ),
            )
          ],
        ),
      ),
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
            title: Text(loc.get('home')),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                  color: AppTheme.primaryTeal,
                ),
              )
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [AppTheme.slateLight, Colors.white, AppTheme.sageLight.withOpacity(0.3)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      widget.isGuest ? loc.get('occasional_patient') : loc.get('welcome_back'),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Que souhaitez-vous faire aujourd\'hui ?',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black45,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildActionCard(
                            context,
                            title: loc.get('queue'),
                            icon: Icons.confirmation_number_outlined,
                            color: AppTheme.primaryTeal,
                            onTap: () => setState(() => _currentIndex = 1),
                          ),
                          _buildActionCard(
                            context,
                            title: loc.get('pharmacy'),
                            icon: Icons.local_pharmacy_outlined,
                            color: AppTheme.success,
                            onTap: () => setState(() => _currentIndex = 2),
                          ),
                            if (!widget.isGuest)
                              _buildActionCard(
                                context,
                                title: 'Ordonnances',
                                icon: Icons.receipt_long_outlined,
                                color: AppTheme.warning,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const PrescriptionsScreen()),
                                  );
                                },
                              ),
                          _buildActionCard(
                            context,
                            title: loc.get('settings'),
                            icon: Icons.settings_outlined,
                            color: AppTheme.accentPurple,
                            onTap: () => setState(() => _currentIndex = 3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: widget.isGuest ? FloatingActionButton.extended(
            onPressed: () => _showQRScanner(context),
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: const Text('Scanner QR', style: TextStyle(fontWeight: FontWeight.w700)),
            backgroundColor: AppTheme.primaryTeal,
            elevation: 8,
          ) : null,
        );
      }
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        blur: isDark ? 20 : 10,
        opacity: isDark ? 0.08 : 0.7,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(isDark ? 0.25 : 0.15), width: 1.5),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: -5,
                  )
                ],
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: loc.get('home')),
          NavigationDestination(icon: const Icon(Icons.confirmation_number_outlined), selectedIcon: const Icon(Icons.confirmation_number), label: loc.get('queue')),
          NavigationDestination(icon: const Icon(Icons.local_pharmacy_outlined), selectedIcon: const Icon(Icons.local_pharmacy), label: loc.get('pharmacy')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: loc.get('settings')),
        ],
      ),
    );
  }
}
