import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../provider/employee_provider.dart';
import '../../services/location_service.dart';
import '../provider/site_provider.dart';

class AddSiteScreen extends ConsumerWidget {
  final Map<String, dynamic>? currentData;

  // 🎯 ConsumerWidget में कंट्रोलर्स को हम कंस्ट्रक्टर के अंदर इनिशियलाइज कर सकते हैं
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  AddSiteScreen({super.key, this.currentData}) {
    // अगर एडिट मोड है, तो पुरानी डिटेल्स पहले ही भर जाएंगी
    if (currentData != null) {
      _nameController.text = currentData!['siteName'] ?? '';
      _latController.text = (currentData!['latitude'] ?? '').toString();
      _lngController.text = (currentData!['longitude'] ?? '').toString();
    }
  }


  static final _selectedSupervisorIdProvider = StateProvider<String?>((ref) => null);
  static final _selectedSupervisorNameProvider = StateProvider<String?>((ref) => null);

  void _saveForm(BuildContext context, WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;

    final supervisorId = ref.read(_selectedSupervisorIdProvider) ?? currentData?['supervisorId'] ?? 'Unassigned';
    final supervisorName = ref.read(_selectedSupervisorNameProvider) ?? currentData?['supervisorName'] ?? 'Unassigned';

    final siteData = {
      'siteName': _nameController.text.trim(),
      'latitude': double.parse(_latController.text.trim()),
      'longitude': double.parse(_lngController.text.trim()),
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'status': currentData?['status'] ?? 'active',
    };

    try {
      if (currentData != null) {
        await ref.read(siteNotifierProvider.notifier).updateSite(currentData!['siteId'], siteData);
      } else {
        await ref.read(siteNotifierProvider.notifier).addSite(siteData);
      }
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(currentData != null ? 'Site updated successfully!' : 'Site created successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // 🎯 जीपीएस से लोकेशन फेच करने का नया रिवरपॉड लॉजिक (No setState)
  void _fetchCurrentLocation(BuildContext context, WidgetRef ref) async {
    // 1. लोडिंग को ट्रू (True) करो
    ref.read(locationLoadingProvider.notifier).state = true;

    try {
      final position = await LocationService.getCurrentLocation();

      if (position != null) {
        // 2. बिना setState के सीधे टेक्स्ट कंट्रोलर्स में वैल्यू डालो (यह तुरंत यूआई पर दिखेगी)
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location fetched successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      // 3. लोडिंग को वापस फॉल्स (False) करो
      ref.read(locationLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesStreamProvider);
    // 🎯 रिवरपॉड से लोडिंग स्टेट को लाइव वॉच (Watch) करो
    final isLoadingLocation = ref.watch(locationLoadingProvider);

    final selectedSupervisorId = ref.watch(_selectedSupervisorIdProvider) ?? currentData?['supervisorId'];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentData != null ? 'Edit Site' : 'Add New Site'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Site Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) => v!.isEmpty ? 'Enter site name' : null,
                ),
                const SizedBox(height: 16),

                // 🎯 जीपीएस बटन (जो अब रिवरपॉड की स्टेट से कंट्रोल हो रहा है)
                OutlinedButton.icon(
                  onPressed: isLoadingLocation ? null : () => _fetchCurrentLocation(context, ref),
                  icon: isLoadingLocation
                      ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepOrange)
                  )
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(isLoadingLocation ? 'Fetching Location...' : 'Get Current Location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(color: Colors.deepOrange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Latitude', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Longitude', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                employeesAsync.when(
                  data: (list) {
                    final supervisors = list.where((e) => e['role'] == 'supervisor').toList();
                    return DropdownButtonFormField<String>(
                      value: selectedSupervisorId,
                      hint: const Text('Assign Supervisor'),
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: supervisors.map((s) {
                        return DropdownMenuItem<String>(
                          value: s['employeeId'],
                          child: Text('${s['name']} (${s['employeeId']})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          final selected = supervisors.firstWhere((element) => element['employeeId'] == value);
                          // 🎯 रिवरपॉड के जरिए स्टेट अपडेट करो, बिना setState के!
                          ref.read(_selectedSupervisorIdProvider.notifier).state = value;
                          ref.read(_selectedSupervisorNameProvider.notifier).state = selected['name'];
                        }
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading supervisors'),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _saveForm(context, ref),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(currentData != null ? 'Update Site' : 'Save Site', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}