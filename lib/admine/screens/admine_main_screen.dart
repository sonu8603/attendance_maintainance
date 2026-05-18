import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../authentication/provider/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/screens/employee_id_screen.dart';
import '../../authentication/screens/waiting_aproval_screen.dart';
import '../../features/help/screens/help_screen.dart';
import '../../route.dart';
import '../screens/employee_list_screen.dart';


class AdminMainScreen extends ConsumerWidget {
  const AdminMainScreen({super.key});


  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) {
      NavigationHelper.pushReplace(context, const EmployeeIdScreen());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Firebase Auth uid se employees collection se data lo
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.help),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HelpScreen(),
                  ),
                );
              }
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context,ref),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ employees collection mein uid se dhundo
        stream: FirebaseFirestore.instance
            .collection('employees')
            .where('authUid', isEqualTo: uid)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          String name = 'Admin';
          String employeeId = '';

          if (snapshot.hasData &&
              snapshot.data!.docs.isNotEmpty) {
            final data = snapshot.data!.docs.first.data()
            as Map<String, dynamic>;
            name = data['name'] ?? 'Admin';
            employeeId = data['employeeId'] ?? '';
          }

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
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.deepOrange.shade100),
                  ),
                  child: Row(
                    children: [
                      // ✅ Photo nahi — initials dikhao
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                        Colors.deepOrange.shade100,
                        child: Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome, Admin',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.deepOrange),
                          ),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (employeeId.isNotEmpty)
                            Text(
                              'ID: $employeeId',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                const Text('Manage',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    children: [
                      _AdminCard(
                        icon: Icons.people,
                        label: 'Employees',
                        subtitle: 'Add / Edit / Delete',
                        color: Colors.blue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const EmployeeListScreen()),
                        ),
                      ),
                      _AdminCard(
                        icon: Icons.location_city,
                        label: 'Sites',
                        subtitle: 'Create / Assign',
                        color: Colors.green,
                        onTap: () {
                          // TODO: SiteListScreen
                        },
                      ),
                      _AdminCard(
                        icon: Icons.approval,
                        label: 'Approvals',
                        subtitle: 'Pending users',
                        color: Colors.orange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const WaitingApprovalScreen()),
                        ),
                      ),
                      _AdminCard(
                        icon: Icons.bar_chart,
                        label: 'Reports',
                        subtitle: 'Attendance + Work',
                        color: Colors.purple,
                        onTap: () {
                          // TODO: ReportsScreen
                        },
                      ),
                      _AdminCard(
                        icon: Icons.checklist,
                        label: 'Daily Work',
                        subtitle: 'Work list',
                        color: Colors.teal,
                        onTap: () {
                          // TODO: DailyWorkScreen
                        },
                      ),
                      _AdminCard(
                        icon: Icons.calendar_today,
                        label: 'Attendance',
                        subtitle: 'Present / Absent',
                        color: Colors.red,
                        onTap: () {
                          // TODO: AttendanceScreen
                        },
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
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
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
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}