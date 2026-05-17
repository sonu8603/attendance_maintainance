import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../authentication/screens/employee_id_screen.dart';
import '../../authentication/services/auth_service.dart';
import '../../route.dart';

class SupervisorMainScreen extends StatelessWidget {
  const SupervisorMainScreen({super.key});

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
        title: const Text('Supervisor Dashboard'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('employees')
            .where('authUid', isEqualTo: uid)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          String name = 'Supervisor';
          String employeeId = '';
          String siteName = 'Not assigned';

          if (snapshot.hasData &&
              snapshot.data!.docs.isNotEmpty) {
            final data = snapshot.data!.docs.first.data()
            as Map<String, dynamic>;
            name = data['name'] ?? 'Supervisor';
            employeeId = data['employeeId'] ?? '';
            siteName = data['siteName'] ?? 'Not assigned';
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
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border:
                    Border.all(color: Colors.teal.shade100),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.teal.shade100,
                        child: Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome, Supervisor',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.teal)),
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
                const Text('Your Tasks',
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
                      _SupervisorCard(
                        icon: Icons.how_to_reg,
                        label: 'Mark Attendance',
                        subtitle: 'Present / Absent',
                        color: Colors.teal,
                        onTap: () {
                          // TODO: AttendanceMarkingScreen
                        },
                      ),
                      _SupervisorCard(
                        icon: Icons.location_on,
                        label: 'Site Status',
                        subtitle: 'Live update',
                        color: Colors.blue,
                        onTap: () {
                          // TODO: SiteStatusScreen
                        },
                      ),
                      _SupervisorCard(
                        icon: Icons.note_add,
                        label: 'Add Notes',
                        subtitle: 'Work done today',
                        color: Colors.orange,
                        onTap: () {
                          // TODO: NotesScreen
                        },
                      ),
                      _SupervisorCard(
                        icon: Icons.people_outline,
                        label: 'My Workers',
                        subtitle: 'View team list',
                        color: Colors.purple,
                        onTap: () {
                          // TODO: WorkerListScreen
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

class _SupervisorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SupervisorCard({
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