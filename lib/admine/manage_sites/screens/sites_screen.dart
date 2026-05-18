import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/site_provider.dart';
import 'add_site_screen.dart';

// सर्च क्वेरी के लिए Notifier
class SiteSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String v) => state = v;
  void clearQuery() => state = '';
}
final siteSearchProvider = NotifierProvider<SiteSearchNotifier, String>(SiteSearchNotifier.new);

class SitesScreen extends ConsumerWidget {
  const SitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(sitesStreamProvider);
    final searchQuery = ref.watch(siteSearchProvider).toLowerCase().trim();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Manage Sites'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔍 सर्च बार
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: TextField(
              onChanged: (v) => ref.read(siteSearchProvider.notifier).updateQuery(v),
              decoration: InputDecoration(
                hintText: 'Search by Site Name or ID...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => ref.read(siteSearchProvider.notifier).clearQuery())
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // 📋 साइट्स की लिस्ट
          Expanded(
            child: sitesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (sites) {
                final filtered = sites.where((s) {
                  final name = (s['siteName'] ?? '').toString().toLowerCase();
                  final id = (s['siteId'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery) || id.contains(searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No sites found', style: TextStyle(color: Colors.grey)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = filtered[index];
                    final siteId = data['siteId'] ?? '';
                    final siteName = data['siteName'] ?? '';
                    final supervisor = data['supervisorName'] ?? 'Unassigned';
                    final radius = data['radiusInMeters'] ?? 150;
                    final status = data['status'] ?? 'active';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Text(siteId, style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(siteName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text('Supervisor: $supervisor', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                    Text('Radius: ${radius}m', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == 'active' ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(status, style: TextStyle(color: status == 'active' ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddSiteScreen(currentData: data))),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    final newStatus = status == 'active' ? 'inactive' : 'active';
                                    ref.read(siteNotifierProvider.notifier).updateSite(siteId, {'status': newStatus});
                                  },
                                  icon: Icon(status == 'active' ? Icons.block : Icons.check_circle, size: 16),
                                  label: Text(status == 'active' ? 'Deactivate' : 'Activate'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: status == 'active' ? Colors.orange : Colors.green,
                                    side: BorderSide(color: status == 'active' ? Colors.orange : Colors.green),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete Site?'),
                                      content: Text('$siteName ko permanently delete karna hai?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    ref.read(siteNotifierProvider.notifier).deleteSite(siteId);
                                  }
                                },
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>  AddSiteScreen())),
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text('Add Site', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}