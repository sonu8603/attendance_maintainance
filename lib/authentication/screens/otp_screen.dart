import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String employeeId;
  final String phone;   // hidden — user ko nahi dikhega
  final String name;

  const OtpScreen({
    super.key,
    required this.employeeId,
    required this.phone,
    required this.name,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  String? _verificationId;
  bool _isSending = true;
  bool _isVerifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendOtp(); // Screen open hote hi OTP bhejo
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isSending = true;
      _error = null;
    });

    await AuthService.sendOtp(
      phone: widget.phone,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _isSending = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isSending = false;
            _error = 'Failed to send OTP. Try again.';
          });
        }
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) return;

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter 6-digit OTP');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final success = await AuthService.verifyOtp(
      verificationId: _verificationId!,
      otp: otp,
    );

    if (!mounted) return;

    if (success) {
      // ✅ OTP sahi — role ke hisab se navigate karo
      await AuthService.saveAuthUid(widget.employeeId);
      await AuthService.navigateByRole(context, widget.employeeId);
    } else {
      setState(() {
        _isVerifying = false;
        _error = 'Wrong OTP. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),

              // Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 56,
                    color: Colors.green,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Hello, ${widget.name.split(' ').first}!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // ✅ Phone nahi dikhate — sirf "registered details" kehte hain
              Text(
                _isSending
                    ? 'Sending OTP...'
                    : 'OTP sent to your registered phone number.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              // OTP input
              _isSending
                  ? const Center(child: CircularProgressIndicator())
                  : TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 10,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '------',
                  hintStyle: TextStyle(
                    letterSpacing: 10,
                    color: Colors.grey.shade300,
                    fontSize: 28,
                  ),
                  errorText: _error,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Colors.green, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Colors.red, width: 1.5),
                  ),
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 18, horizontal: 20),
                ),
                onSubmitted: (_) => _verifyOtp(),
              ),

              const SizedBox(height: 24),

              // Verify button
              if (!_isSending)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isVerifying
                        ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                        : const Text(
                      'Verify & Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Resend OTP
              if (!_isSending && !_isVerifying)
                Center(
                  child: TextButton(
                    onPressed: _sendOtp,
                    child: const Text(
                      'Resend OTP',
                      style: TextStyle(color: Colors.grey),
                    ),
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