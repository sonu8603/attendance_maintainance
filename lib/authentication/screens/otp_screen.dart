import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admine/manage_employee/screens/admine_main_screen.dart';
import '../../employees/screens/employee_main_screen.dart';
import '../../superviser/screens/supervisor_main_screen.dart';
import '../../route.dart';
import '../provider/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String employeeId;
  final String phone;
  final String name;

  const OtpScreen({
    super.key,
    required this.employeeId,
    required this.phone,
    required this.name,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isSending = true;

  @override
  void initState() {
    super.initState();
    // पोस्ट फ्रेम कॉलबैक में सेफ तरीके से ओटीपी ट्रिगर करें
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
  }

  Future<void> _sendOtp() async {
    setState(() => _isSending = true);

    await ref.read(authProvider.notifier).sendOtp(
      phone: widget.phone,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() => _isSending = false);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isSending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OTP Send Failed: $error'), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;

    // 🎯 लोकल वेरिएबल के बजाय सीधे हमारे भरोसेमंद प्रदाता की स्टेट से आईडी उठाओ
    final vId = ref.read(authProvider).verificationId;
    if (vId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification ID missing. Resend OTP.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .verifyOtp(verificationId: vId, otp: otp);

    if (!mounted) return;

    if (success) {
      final role = ref.read(authProvider).role ?? '';
      _navigateByRole(role);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong OTP. Try again.'), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateByRole(String role) {
    switch (role) {
      case 'admin':
        NavigationHelper.pushReplace(context, const AdminMainScreen());
        break;
      case 'supervisor':
        NavigationHelper.pushReplace(context, const SupervisorMainScreen());
        break;
      case 'employee':
        NavigationHelper.pushReplace(context, const EmployeeMainScreen());
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role not assigned. Contact admin.'), backgroundColor: Colors.red),
        );
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isVerifying = authState.status == AuthStatus.loading;
    final error = authState.status == AuthStatus.error ? authState.errorMessage : null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(authProvider.notifier).resetOtpStatus();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.lock_outline, size: 56, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Hello, ${widget.name.split(' ').first}!',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isSending ? 'Sending OTP...' : 'OTP sent to your registered phone number.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 36),

              _isSending
                  ? const Center(child: CircularProgressIndicator())
                  : TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 10),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '------',
                  hintStyle: TextStyle(letterSpacing: 10, color: Colors.grey.shade300, fontSize: 28),
                  errorText: error,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.green, width: 2)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
                onSubmitted: (_) => _verifyOtp(),
              ),
              const SizedBox(height: 24),

              if (!_isSending)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isVerifying ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: isVerifying
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Verify & Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              const SizedBox(height: 16),

              if (!_isSending && !isVerifying)
                Center(
                  child: TextButton(
                    onPressed: () {
                      _otpController.clear();
                      _sendOtp();
                    },
                    child: const Text('Resend OTP', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}