import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class PrescriptionOrderScreen extends StatefulWidget {
  final Map<String, dynamic> prescription;

  const PrescriptionOrderScreen({super.key, required this.prescription});

  @override
  State<PrescriptionOrderScreen> createState() => _PrescriptionOrderScreenState();
}

class _PrescriptionOrderScreenState extends State<PrescriptionOrderScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _pharmacies = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchCapablePharmacies();
  }

  Future<void> _fetchCapablePharmacies() async {
    try {
      // 1. Get Location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Les services de localisation sont désactivés.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Les permissions de localisation sont refusées.');
        }
      }
      
      _currentPosition = await Geolocator.getCurrentPosition();

      // 2. Fetch Pharmacies
      final response = await ApiClient().dio.get('/consultations/prescriptions/${widget.prescription['id']}/pharmacies');
      List<dynamic> results = response.data;

      // 3. Calculate distance and sort
      for (var result in results) {
        final pharmacy = result['pharmacy'];
        double distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          pharmacy['latitude'],
          pharmacy['longitude'],
        );
        result['distance'] = distance;
      }

      results.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      if (mounted) {
        setState(() {
          _pharmacies = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - math.cos((lat2 - lat1) * p) / 2 + 
            math.cos(lat1 * p) * math.cos(lat2 * p) * 
            (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  Future<void> _showOrderDialog(Map<String, dynamic> pharmacyData) async {
    String deliveryMethod = 'pickup';
    TextEditingController addressController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Confirmer la commande'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pharmacie: ${pharmacyData['pharmacy']['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Méthode de réception:'),
                    RadioListTile(
                      title: const Text('Retrait sur place'),
                      value: 'pickup',
                      groupValue: deliveryMethod,
                      onChanged: (val) => setState(() => deliveryMethod = val.toString()),
                    ),
                    RadioListTile(
                      title: const Text('Livraison à domicile'),
                      value: 'delivery',
                      groupValue: deliveryMethod,
                      onChanged: (val) => setState(() => deliveryMethod = val.toString()),
                    ),
                    if (deliveryMethod == 'delivery') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse de livraison',
                          border: OutlineInputBorder(),
                        ),
                      )
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
                  onPressed: () async {
                    if (deliveryMethod == 'delivery' && addressController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez saisir une adresse.')));
                      return;
                    }
                    Navigator.pop(context);
                    await _placeOrder(pharmacyData['pharmacy']['id'], deliveryMethod, addressController.text);
                  },
                  child: const Text('Valider', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _placeOrder(int pharmacyId, String method, String address) async {
    setState(() => _isLoading = true);
    try {
      await ApiClient().dio.post(
        '/consultations/prescriptions/${widget.prescription['id']}/order',
        data: {
          'pharmacyId': pharmacyId,
          'deliveryMethod': method,
          'deliveryAddress': method == 'delivery' ? address : null,
        }
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande envoyée avec succès !')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la commande.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une pharmacie'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _pharmacies.isEmpty
                  ? const Center(child: Text("Aucune pharmacie n'a tous ces médicaments en stock."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pharmacies.length,
                      itemBuilder: (context, index) {
                        final data = _pharmacies[index];
                        final pharmacy = data['pharmacy'];
                        final distance = data['distance'] as double;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            onTap: () => _showOrderDialog(data),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Image.asset('assets/images/pharmacy_logo.png', fit: BoxFit.contain),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(pharmacy['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text(pharmacy['address'], style: const TextStyle(color: Colors.grey)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 16, color: AppTheme.primaryTeal),
                                            const SizedBox(width: 4),
                                            Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
                                            const Spacer(),
                                            const Icon(Icons.check_circle, size: 16, color: AppTheme.success),
                                            const SizedBox(width: 4),
                                            const Text('En stock', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
