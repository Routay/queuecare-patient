import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:queuecare_patient/core/localization/app_localizations.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/features/pharmacy/pharmacy_detail_screen.dart';
import 'package:queuecare_patient/core/network/api_client.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _pharmacies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    try {
      final response = await ApiClient().dio.get('/pharmacies/');
      if (mounted) {
        setState(() {
          _pharmacies = List<Map<String, dynamic>>.from(response.data);
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Zone de recherche
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: loc.get('search_medicine'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () {},
              ),
            ),
          ),
        ),
        
        // Carte Mapbox / Leaflet
        Expanded(
          flex: 3,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(14.6928, -17.4467), // Dakar center
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.queuecare.patient',
              ),
              if (!_isLoading && _pharmacies.isNotEmpty)
                MarkerLayer(
                  markers: _pharmacies.map((p) => Marker(
                    point: LatLng(p['latitude'], p['longitude']),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.local_pharmacy,
                      color: AppTheme.success,
                      size: 40,
                    ),
                  )).toList(),
                ),
            ],
          ),
        ),
        
        // Liste des pharmacies
        Expanded(
          flex: 2,
          child: Container(
            color: isDark ? AppTheme.slateDark : AppTheme.slateLight,
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: AppTheme.danger))))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pharmacies.length,
                    itemBuilder: (context, index) {
                      final p = _pharmacies[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.success.withOpacity(0.1),
                            child: const Icon(Icons.medical_services, color: AppTheme.success),
                          ),
                          title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(p['address']),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PharmacyDetailScreen(pharmacy: p),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
