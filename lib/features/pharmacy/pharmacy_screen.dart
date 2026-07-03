import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shimmer/shimmer.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:queuecare_patient/core/localization/app_localizations.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/features/pharmacy/pharmacy_detail_screen.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'dart:ui' as ui;

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _pharmacies = [];
  List<Map<String, dynamic>> _filteredPharmacies = [];
  
  // Tab management (0 = Médicaments, 1 = Pharmacies)
  int _selectedTab = 0;
  
  // Medicines aggregation
  List<Map<String, dynamic>> _allMedicines = [];
  List<Map<String, dynamic>> _filteredMedicines = [];

  bool _isLoading = true;
  String? _error;
  late AnimationController _animController;
  
  // Geolocation
  LatLng _userLocation = const LatLng(14.6928, -17.4467); // Dakar par défaut
  bool _hasLocation = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _searchController.addListener(_onSearchChanged);
    
    _initData();
  }
  
  Future<void> _initData() async {
    await _getUserLocation();
    await _loadPharmacies();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _hasLocation = true;
        });
      }
    } catch (e) {
      debugPrint("Erreur de géolocalisation: $e");
    }
  }

  Future<void> _loadPharmacies() async {
    try {
      final response = await ApiClient().dio.get('/pharmacies/');
      if (mounted) {
        final List<Map<String, dynamic>> rawPharmacies = List<Map<String, dynamic>>.from(response.data);
        
        // Calculate distance for each pharmacy
        for (var p in rawPharmacies) {
          if (p['latitude'] != null && p['longitude'] != null) {
            double distanceInMeters = Geolocator.distanceBetween(
              _userLocation.latitude, _userLocation.longitude,
              p['latitude'], p['longitude']
            );
            p['distance'] = distanceInMeters;
          } else {
            p['distance'] = double.infinity;
          }
        }
        
        // Sort pharmacies by distance
        rawPharmacies.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
        
        // Extract unique medicines
        Map<String, Map<String, dynamic>> medsMap = {};
        for (var p in rawPharmacies) {
          if (p['stock'] != null) {
            for (var item in p['stock']) {
              String name = item['name'];
              if (!medsMap.containsKey(name)) {
                medsMap[name] = {
                  'name': name,
                  'category': item['category'] ?? 'Général',
                  'availablePharmacies': []
                };
              }
              // Only add if in stock
              if (item['inStock'] == true) {
                medsMap[name]!['availablePharmacies'].add(p);
              }
            }
          }
        }
        
        // Convert to list and sort alphabetically
        List<Map<String, dynamic>> medsList = medsMap.values.toList();
        medsList.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

        setState(() {
          _pharmacies = rawPharmacies;
          _filteredPharmacies = rawPharmacies;
          _allMedicines = medsList;
          _filteredMedicines = medsList;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Impossible de joindre le serveur. $e";
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (_selectedTab == 0) {
        // Search medicines
        _filteredMedicines = _allMedicines.where((m) => m['name'].toString().toLowerCase().contains(query)).toList();
      } else {
        // Search pharmacies
        _filteredPharmacies = _pharmacies.where((p) => 
          p['name'].toString().toLowerCase().contains(query) || 
          p['address'].toString().toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  String _formatDistance(double meters) {
    if (meters == double.infinity) return "? km";
    if (meters < 1000) return "${meters.toInt()} m";
    return "${(meters / 1000).toStringAsFixed(1)} km";
  }

  void _showMedicineAvailabilitySheet(BuildContext context, Map<String, dynamic> medicine) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, dynamic>> availablePharms = List<Map<String, dynamic>>.from(medicine['availablePharmacies']);
    
    // Sort available pharmacies by distance
    availablePharms.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: -5,
            )
          ]
        ),
        child: Column(
          children: [
            // Handle indicator
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.medication_liquid_rounded, color: AppTheme.primaryTeal, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine['name'],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppTheme.slateDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${availablePharms.length} pharmacie(s) à proximité",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            
            // List of pharmacies
            Expanded(
              child: availablePharms.isEmpty
                ? Center(
                    child: Text(
                      "Rupture de stock dans les environs.",
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: availablePharms.length,
                    itemBuilder: (context, index) {
                      final p = availablePharms[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_pharmacy, color: AppTheme.success, size: 20),
                          ),
                          title: Text(
                            p['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.slateDark,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.directions_walk_rounded, size: 14, color: AppTheme.primaryTeal),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDistance(p['distance']),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryTeal,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            ),
                            child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.slateDark),
                          ),
                          onTap: () {
                            Navigator.pop(context); // Close bottom sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PharmacyDetailScreen(pharmacy: p)),
                            );
                          },
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0A0F1E), const Color(0xFF0F172A)]
              : [const Color(0xFFF0FDFA), Colors.white],
        ),
      ),
      child: Column(
        children: [
          // Header with tabs and search
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Image.asset(
                          'assets/images/pharmacy_illustration.png',
                          width: 28,
                          height: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.get('pharmacy'),
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 24,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedTab == 0 ? 'Trouver un médicament' : 'Pharmacies à proximité',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Segmented Control
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTab = 0;
                                _searchController.clear();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _selectedTab == 0 ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ] : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Médicaments",
                                style: TextStyle(
                                  fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w600,
                                  color: _selectedTab == 0 
                                      ? (isDark ? Colors.white : AppTheme.slateDark) 
                                      : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTab = 1;
                                _searchController.clear();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _selectedTab == 1 ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ] : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Pharmacies",
                                style: TextStyle(
                                  fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w600,
                                  color: _selectedTab == 1 
                                      ? (isDark ? Colors.white : AppTheme.slateDark) 
                                      : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                          blurRadius: 16,
                          spreadRadius: -4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: _selectedTab == 0 ? loc.get('search_medicine') : 'Rechercher une pharmacie...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Map (Only visible in Pharmacies tab)
          if (_selectedTab == 1)
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                      blurRadius: 20,
                      spreadRadius: -6,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _userLocation,
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.queuecare.patient',
                      ),
                      if (_hasLocation)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _userLocation,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.my_location, color: Colors.blue, size: 24),
                            ),
                          ]
                        ),
                      if (!_isLoading && _pharmacies.isNotEmpty)
                        MarkerLayer(
                          markers: _pharmacies.map((p) => Marker(
                            point: LatLng(p['latitude'], p['longitude']),
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PharmacyDetailScreen(pharmacy: p)),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.success.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.local_pharmacy,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          )).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
          if (_selectedTab == 1) const SizedBox(height: 16),
          
          // Lists Area
          Expanded(
            flex: _selectedTab == 1 ? 2 : 5, // Take more space when map is hidden
            child: _isLoading 
              ? _buildShimmerLoading(isDark)
              : _error != null
                ? _buildErrorState(isDark)
                : (_selectedTab == 0 ? _buildMedicinesList(isDark) : _buildPharmaciesList(isDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[300]!,
          highlightColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120, height: 14, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: double.infinity, height: 12, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.wifi_off_rounded, color: AppTheme.danger, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Connexion impossible',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isDark ? Colors.white : AppTheme.slateDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicinesList(bool isDark) {
    if (_filteredMedicines.isEmpty) {
      return Center(
        child: Text(
          "Aucun médicament trouvé.",
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
      itemCount: _filteredMedicines.length,
      itemBuilder: (context, index) {
        final med = _filteredMedicines[index];
        final bool isAvailable = (med['availablePharmacies'] as List).isNotEmpty;
        
        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final delay = (index % 10) * 0.05; // Quick stagger for lists
            final progress = ((_animController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
            return Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - progress)),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                width: 1,
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _showMedicineAvailabilitySheet(context, med),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.medication, color: AppTheme.primaryTeal),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDark ? Colors.white : AppTheme.slateDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              med['category'],
                              style: TextStyle(
                                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAvailable ? AppTheme.success.withOpacity(0.1) : AppTheme.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAvailable ? 'Disponible' : 'Rupture',
                          style: TextStyle(
                            color: isAvailable ? AppTheme.success : AppTheme.danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPharmaciesList(bool isDark) {
    if (_filteredPharmacies.isEmpty) {
      return Center(
        child: Text(
          "Aucune pharmacie trouvée.",
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
      itemCount: _filteredPharmacies.length,
      itemBuilder: (context, index) {
        final p = _filteredPharmacies[index];
        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final delay = (index % 5) * 0.1;
            final progress = ((_animController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
            return Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - progress)),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.06) 
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 12,
                  spreadRadius: -4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PharmacyDetailScreen(pharmacy: p),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.success.withOpacity(0.1),
                              AppTheme.success.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/images/pharmacy_illustration.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDark ? Colors.white : AppTheme.slateDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined, 
                                  size: 14, 
                                  color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    p['address'],
                                    style: TextStyle(
                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (p['distance'] != null)
                            Row(
                              children: [
                                Icon(Icons.directions_walk_rounded, size: 12, color: AppTheme.success),
                                const SizedBox(width: 2),
                                Text(
                                  _formatDistance(p['distance']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded, 
                              size: 12, 
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
