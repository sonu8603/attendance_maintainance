import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/provider/firebase_provider.dart';

enum AuthStatus { initial, loading, authenticated, error }

class AuthState {
  final AuthStatus status;
  final String? employeeId;
  final String? role;
  final String? errorMessage;
  final Map<String, dynamic>? employeeData;
  final String? verificationId; // 🎯 स्टेट में बना रहेगा
  final bool otpSent;           // 🎯 स्टेट में बना रहेगा

  const AuthState({
    this.status = AuthStatus.initial,
    this.employeeId,
    this.role,
    this.errorMessage,
    this.employeeData,
    this.verificationId,
    this.otpSent = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? employeeId,
    String? role,
    String? errorMessage,
    Map<String, dynamic>? employeeData,
    String? verificationId,
    bool? otpSent,
  }) {
    return AuthState(
      status: status ?? this.status,
      employeeId: employeeId ?? this.employeeId,
      role: role ?? this.role,
      errorMessage: errorMessage ?? this.errorMessage,
      employeeData: employeeData ?? this.employeeData,
      verificationId: verificationId ?? this.verificationId,
      otpSent: otpSent ?? this.otpSent,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<Map<String, dynamic>?> checkEmployeeId(String employeeId) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final cleanId = employeeId.toUpperCase().trim();

    try {
      final db = ref.read(firestoreProvider);

      final doc = await db
          .collection('employees')
          .doc(cleanId)
          .get(const GetOptions(source: Source.server));

      if (!doc.exists) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Invalid Employee ID. Contact admin.',
        );
        return null;
      }

      final data = doc.data()!;
      if (data['status'] != 'active') {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Account inactive. Contact admin.',
        );
        return null;
      }

      state = state.copyWith(
        status: AuthStatus.initial,
        employeeId: cleanId,
        employeeData: data,
      );
      return data;

    } catch (e) {
      String errUserMsg = 'Something went wrong. Try again.';
      if (e.toString().contains('unavailable') || e.toString().contains('network')) {
        errUserMsg = 'Network Error: Internet chalu karo ya WiFi check karo.';
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: errUserMsg,
      );
      rethrow;
    }
  }


  Future<void> sendOtp({
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final auth = ref.read(firebaseAuthProvider);

      await auth.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        timeout: const Duration(seconds: 30),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: e.message ?? 'OTP failed',
            otpSent: false,
          );
          onError(e.message ?? 'OTP failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          // 🎯 स्क्रीन के काम के लिए स्टेट भी सेट कर दी
          state = state.copyWith(
            status: AuthStatus.initial,
            verificationId: verificationId,
            otpSent: true,
          );
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String vId) {
          state = state.copyWith(verificationId: vId);
        },
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
      onError(e.toString());
    }
  }


  void resetOtpStatus() {
    state = state.copyWith(otpSent: false, verificationId: null, errorMessage: null);
  }

  Future<bool> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final auth = ref.read(firebaseAuthProvider);
      final db = ref.read(firestoreProvider);

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await auth.signInWithCredential(credential);
      final uid = userCredential.user?.uid;

      if (uid != null && state.employeeId != null) {
        await db
            .collection('employees')
            .doc(state.employeeId!)
            .update({'authUid': uid});
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        role: state.employeeData?['role'],
      );
      return true;

    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Wrong OTP. Try again.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    final auth = ref.read(firebaseAuthProvider);
    await auth.signOut();
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);