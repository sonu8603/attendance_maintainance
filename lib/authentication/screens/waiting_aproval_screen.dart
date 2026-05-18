import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../route.dart';
import '../../admine/screens/admine_main_screen.dart';
import '../../employees/screens/employee_main_screen.dart';
import '../../superviser/screens/supervisor_main_screen.dart';
import '../provider/auth_provider.dart';
import 'employee_id_screen.dart';

class WaitingApprovalScreen extends ConsumerWidget {
  const WaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ authProvider se employeeId lo — uid nahi
    final employeeId = ref.read(authProvider).employeeId ?? '';

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('employees')
            .doc(employeeId) // ✅ employeeId se dhundo, uid se nahi
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data =
            snapshot.data!.data() as Map<String, dynamic>?;
            final role = data?['role'] ?? 'pending';

            if (role != 'pending') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _navigateByRole(context, role);
              });
            }
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top,
                      size: 80, color: Colors.orange),
                  const SizedBox(height: 24),
                  const Text('Approval Pending',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                    'Your profile has been submitted.\nPlease wait for admin approval.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 40),
                  TextButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) {
                        NavigationHelper.pushReplace(
                            context, const EmployeeIdScreen());
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateByRole(BuildContext context, String role) {
    switch (role) {
      case 'admin':
        NavigationHelper.pushReplace(context, const AdminMainScreen());
        break;
      case 'supervisor':
        NavigationHelper.pushReplace(
            context, const SupervisorMainScreen());
        break;
      case 'employee':
        NavigationHelper.pushReplace(context, const EmployeeMainScreen());
        break;
    }
  }
}