import 'package:attendance_maintainance/features/help/screens/help_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/screens/employee_id_screen.dart';
import '../../authentication/provider/auth_provider.dart';
import '../../route.dart';
import '../provider/employee_profile_provider.dart';
import '../provider/leave_provider.dart';



class EmployeeMainScreen extends ConsumerWidget {
  const EmployeeMainScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) {
      NavigationHelper.pushReplace(context, const EmployeeIdScreen());
    }
  }

  @override
  // ✅ build mein WidgetRef ref parameter aaya
  Widget build(BuildContext context, WidgetRef ref) {

    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.help),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>HelpScreen()));
              }
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),

      // ✅ StreamBuilder hata diya — profileAsync.when use karo
      body: profileAsync.when(
        // Loading state
        loading: () => const Center(child: CircularProgressIndicator()),

        // Error state
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(myProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),

        // Data state
        data: (profile) {
          final name = profile?['name'] ?? 'Employee';
          final employeeId = profile?['employeeId'] ?? '';
          final siteName = profile?['siteName'] ?? 'Not assigned yet';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Welcome card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.indigo.shade100,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'E',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Welcome',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.indigo)),
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              'ID: $employeeId  •  $siteName',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                const Text('My Info',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    children: [
                      _EmployeeCard(
                        icon: Icons.calendar_month,
                        label: 'My Attendance',
                        subtitle: 'View history',
                        color: Colors.indigo,
                        onTap: () {
                          // TODO: MyAttendanceScreen
                        },
                      ),
                      _EmployeeCard(
                        icon: Icons.location_city,
                        label: 'My Site',
                        subtitle: siteName,
                        color: Colors.teal,
                        onTap: () {
                          // TODO: SiteInfoScreen
                        },
                      ),
                      _EmployeeCard(
                        icon: Icons.beach_access,
                        label: 'Apply Leave',
                        subtitle: 'Request time off',
                        color: Colors.orange,
                        onTap: () => _showLeaveDialog(
                          context,
                          ref,
                          employeeId,
                        ),
                      ),
                      _EmployeeCard(
                        icon: Icons.currency_rupee,
                        label: 'Salary',
                        subtitle: 'Coming soon',
                        color: Colors.grey,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ Leave apply dialog — leaveNotifierProvider use karta hai
  void _showLeaveDialog(
      BuildContext context, WidgetRef ref, String employeeId) {
    final reasonController = TextEditingController();
    String? fromDate;
    String? toDate;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Apply Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // Date pickers
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(fromDate ?? 'From Date'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        fromDate =
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(toDate ?? 'To Date'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        toDate =
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (reasonController.text.isEmpty ||
                  fromDate == null ||
                  toDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Sab fields fill karo')),
                );
                return;
              }

              Navigator.pop(ctx);

              // ✅ leaveNotifierProvider se leave apply karo
              final success = await ref
                  .read(leaveNotifierProvider.notifier)
                  .applyLeave(
                employeeId: employeeId,
                reason: reasonController.text.trim(),
                fromDate: fromDate!,
                toDate: toDate!,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Leave applied successfully!'
                        : 'Failed. Try again.'),
                    backgroundColor:
                    success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _EmployeeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style:
                const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}