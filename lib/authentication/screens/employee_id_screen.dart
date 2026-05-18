import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/auth_provider.dart';
import 'otp_screen.dart';

class EmployeeIdScreen extends ConsumerStatefulWidget {
  const EmployeeIdScreen({super.key});

  @override
  ConsumerState<EmployeeIdScreen> createState() => _EmployeeIdScreenState();
}

class _EmployeeIdScreenState extends ConsumerState<EmployeeIdScreen> {
  final _idController = TextEditingController();

  Future<void> _checkId() async {
    final id = _idController.text.trim().toUpperCase();
    if (id.isEmpty) return;

    final data = await ref.read(authProvider.notifier).checkEmployeeId(id);

    if (!mounted) return;
    if (data == null) return; // Error सीधे प्रदाता की स्टेट से इनपुट बॉक्स में दिखेगा

    final phone = data['phone'] ?? '';
    if (phone.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          employeeId: id,
          phone: phone,
          name: data['name'] ?? '',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final error = authState.status == AuthStatus.error ? authState.errorMessage : null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.deepOrange.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.badge_outlined, size: 56, color: Colors.deepOrange),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Enter Employee ID', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Your company has given you a unique ID.\nEnter it below to continue.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _idController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'EMP001',
                  hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 22, letterSpacing: 4, fontWeight: FontWeight.bold),
                  errorText: error,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.deepOrange, width: 2)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
                onSubmitted: (_) => _checkId(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _checkId,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}