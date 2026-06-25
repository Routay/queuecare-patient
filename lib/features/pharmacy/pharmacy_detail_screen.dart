import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';

class PharmacyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pharmacy;

  const PharmacyDetailScreen({super.key, required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Utilisation des données de stock réelles provenant de l'API
    final List<dynamic> realStock = pharmacy['stock'] ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(pharmacy['latitude'], pharmacy['longitude']),
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Disable map interaction in header
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.queuecare.patient',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(pharmacy['latitude'], pharmacy['longitude']),
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.location_on, color: AppTheme.danger, size: 50),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: isDark ? Colors.black54 : Colors.white.withOpacity(0.8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: isDark ? Colors.white : Colors.black,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pharmacy['name'],
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Ouvert",
                          style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pharmacy['address'],
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lancement de la navigation GPS...')),
                            );
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text("Y aller"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Appel de la pharmacie...')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                        ),
                        child: const Icon(Icons.phone, color: AppTheme.primaryTeal),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Text(
                    "Disponibilité",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  if (realStock.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Aucune information de stock disponible.", style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...realStock.map((item) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: item['inStock'] 
                            ? const Chip(label: Text('En Stock', style: TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: AppTheme.success)
                            : const Chip(label: Text('Rupture', style: TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: AppTheme.danger),
                      ),
                    )),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
