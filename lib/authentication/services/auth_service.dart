import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../admine/screens/admine_main_screen.dart';
import '../../employees/screens/employee_main_screen.dart';
import '../../route.dart';
import '../../superviser/screens/supervisor_main_screen.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ Step 1 — Employee ID check karo Firestore mein
  static Future<Map<String, dynamic>?> checkEmployeeId(
      String employeeId) async {
    try {
      print('Checking ID: ${employeeId.toUpperCase().trim()}');

      final doc = await _db
          .collection('employees')
          .doc(employeeId.toUpperCase().trim())
          .get();

      print('Doc exists: ${doc.exists}'); // ← add karo

      if (!doc.exists) return null;

      final data = doc.data()!;
      print('Data: $data'); // ← add karo
      print('Status: ${data['status']}'); // ← add karo

      if (data['status'] != 'active') return null;
      return data;
    } catch (e) {
      print('ID check error: $e');
      rethrow;
    }
  }

  // ✅ Step 2 — OTP bhejo
  static Future<String?> sendOtp({
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'OTP failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (_) {},
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ✅ Step 3 — OTP verify karo
  static Future<bool> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      print('OTP verify error: $e');
      return false;
    }
  }

  // ✅ NEW — OTP verify hone ke baad authUid save karo
  // Taki dashboard employees collection se data fetch kar sake
  static Future<void> saveAuthUid(String employeeId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      await _db
          .collection('employees')
          .doc(employeeId.toUpperCase().trim())
          .update({'authUid': uid});
    } catch (e) {
      print('saveAuthUid error: $e');
    }
  }

  // ✅ Step 4 — Role check karke navigate karo
  static Future<void> navigateByRole(
      BuildContext context, String employeeId) async {
    try {
      final doc = await _db
          .collection('employees')
          .doc(employeeId.toUpperCase().trim())
          .get();

      if (!doc.exists) return;

      final role = doc.data()?['role'] ?? '';

      switch (role) {
        case 'admin':
          NavigationHelper.pushReplace(
              context, const AdminMainScreen());
          break;
        case 'supervisor':
          NavigationHelper.pushReplace(
              context, const SupervisorMainScreen());
          break;
        case 'employee':
          NavigationHelper.pushReplace(
              context, const EmployeeMainScreen());
          break;
        default:
          _showError(context, 'Role not assigned. Contact admin.');
      }
    } catch (e) {
      _showError(context, 'Something went wrong.');
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }
}