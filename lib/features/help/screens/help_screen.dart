import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../provider/help_provider.dart';
import '../widgets/support_title.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});


  Future<void> sendEmail({
    required String email,
    required String subject,
    required String body,
  }) async {

    final url =
        'mailto:$email?subject=$subject&body=$body';

    print(url);

    try {

      await launchUrl(
        Uri.parse(url),

        mode:
        LaunchMode.externalApplication,
      );

      print('EMAIL APP OPENED');

    } catch (e) {

      print('EMAIL ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentEmployeeProvider);

    final role = user['role'] ?? '';
    final employeeId = user['employeeId'] ?? '';
    final name = user['name'] ?? '';
    final email = user['email'] ?? '';

    final adminEmailAsync = ref.watch(adminEmailProvider);
    final supervisorEmailAsync = ref.watch(supervisorEmailProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// ================= ADMIN =================
              if (role == 'admin') ...[
                SupportTile(
                  icon: Icons.developer_mode,
                  title: 'Contact Developer',
                  subtitle: 'Report app issue to developer',
                  onTap: () {
                    sendEmail(
                      email: 'developer@gmail.com',
                      subject: 'Admin Support - $employeeId',
                      body: '''
Employee ID : $employeeId
Name : $name
Role : $role
Email : $email

Describe your issue below:

''',
                    );
                  },
                ),
              ],

              /// ================= SUPERVISOR =================
              if (role == 'supervisor') ...[
                SupportTile(
                  icon: Icons.bug_report,
                  title: 'Report Bug',
                  subtitle: 'Report app issue to developer',
                  onTap: () {
                    sendEmail(
                      email: 'developer@gmail.com',
                      subject: 'Bug Report - $employeeId',
                      body: '''
Employee ID : $employeeId
Name : $name
Role : $role
Email : $email

Describe your issue below:

''',
                    );
                  },
                ),
                adminEmailAsync.when(
                  data: (adminEmail) {
                    return SupportTile(
                      icon: Icons.admin_panel_settings,
                      title: 'Contact Admin',
                      subtitle: 'Mail admin for help',
                      onTap: () {
                        sendEmail(
                          email: adminEmail,
                          subject: 'Supervisor Help - $employeeId',
                          body: '''
Employee ID : $employeeId
Name : $name
Role : $role
Email : $email

Describe your issue below:

''',
                        );
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),
              ],

              /// ================= EMPLOYEE =================
              if (role == 'employee') ...[
                SupportTile(
                  icon: Icons.bug_report_outlined,
                  title: 'Report Bug',
                  subtitle: 'Report app issue to developer',
                  onTap: () {
                    sendEmail(
                      email: 'developer@gmail.com',
                      subject: 'Bug Report - $employeeId',
                      body: '''
Employee ID : $employeeId
Name : $name
Role : $role
Email : $email

Describe your issue below:

''',
                    );
                  },
                ),
                supervisorEmailAsync.when(
                  data: (supervisorEmail) {
                    return SupportTile(
                      icon: Icons.support_agent,
                      title: 'Contact Supervisor',
                      subtitle: 'Mail supervisor for help',
                      onTap: () {
                        sendEmail(
                          email: supervisorEmail,
                          subject: 'Employee Help - $employeeId',
                          body: '''
Employee ID : $employeeId
Name : $name
Role : $role
Email : $email

Describe your issue below:

''',
                        );
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}