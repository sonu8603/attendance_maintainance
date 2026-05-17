import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../authentication/screens/employee_id_screen.dart';

import '../../authentication/services/auth_service.dart';
import '../../route.dart';

class EmployeeMainScreen extends StatelessWidget {
  const EmployeeMainScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.signOut();
    if (context.mounted) {
      NavigationHelper.pushReplace(
          context, const EmployeeIdScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ employees collection — authUid se match karo
        stream: FirebaseFirestore.instance
            .collection('employees')
            .where('authUid', isEqualTo: uid)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          String name = 'Employee';
          String employeeId = '';
          String siteName = 'Not assigned yet';

          if (snapshot.data!.docs.isNotEmpty) {
            final data = snapshot.data!.docs.first.data()
            as Map<String, dynamic>;
            name = data['name'] ?? 'Employee';
            employeeId = data['employeeId'] ?? '';
            siteName = data['siteName'] ?? 'Not assigned yet';
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
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.indigo.shade100),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                        Colors.indigo.shade100,
                        child: Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : 'E',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.indigo)),
                          Text(name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              )),
                          Text(
                            'ID: $employeeId  •  $siteName',
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
                const Text('My Info',
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
                        onTap: () {
                          // TODO: LeaveApplyScreen
                        },
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
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}