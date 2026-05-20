import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/provider/firebase_provider.dart';

/// =========================
/// EMPLOYEES STREAM
/// =====================

final employeesStreamProvider =
StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(firestoreProvider);

  return db
      .collection('employees')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs.map((e) => e.data()).toList(),
  );
});


/// SEARCH

final employeeSearchProvider =
StateProvider<String>((ref) => '');


/// SELECTED SITE PROVIDERS

final selectedSiteIdProvider =
StateProvider<String?>((ref) => null);

final selectedSiteNameProvider =
StateProvider<String?>((ref) => null);

/// =========================
/// SELECTED ROLE
/// =========================
final selectedRoleProvider =
StateProvider<String?>((ref) => null);


/// EMPLOYEE STATE

class EmployeeState {
  final bool isLoading;
  final String? error;

  const EmployeeState({
    this.isLoading = false,
    this.error,
  });

  EmployeeState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return EmployeeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// =========================
/// NOTIFIER
/// =========================
class EmployeeNotifier extends Notifier<EmployeeState> {
  @override
  EmployeeState build() {
    return const EmployeeState();
  }

  /// =========================
  /// GENERATE EMPLOYEE ID
  /// =========================
  Future<String> generateEmployeeId() async {
    final db = ref.read(firestoreProvider);

    final snap = await db
        .collection('employees')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      return 'EMP001';
    }

    final lastId = snap.docs.first.id;

    final num =
        int.tryParse(lastId.replaceAll('EMP', '')) ?? 0;

    return 'EMP${(num + 1).toString().padLeft(3, '0')}';
  }

  /// =========================
  /// ADD EMPLOYEE
  /// =========================
  Future<String?> addEmployee({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String role,
    required String siteId,
    required String siteName,
    required String createdBy,

  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final db = ref.read(firestoreProvider);

      final empId = await generateEmployeeId();

      await db.collection('employees').doc(empId).set({
        'employeeId': empId,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,

        'role': role,

        'siteId': siteId,
        'siteName': siteName,

        'status': 'active',

        'authUid': '',

        'createdBy': createdBy,

        'createdAt': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(isLoading: false);

      return empId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return null;
    }
  }

  /// =========================
  /// UPDATE EMPLOYEE
  /// =========================
  Future<bool> updateEmployee(
      String empId,
      Map<String, dynamic> data,
      ) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final db = ref.read(firestoreProvider);

      await db
          .collection('employees')
          .doc(empId)
          .update(data);

      state = state.copyWith(isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return false;
    }
  }

  /// =========================
  /// DELETE EMPLOYEE
  /// =========================
  Future<bool> deleteEmployee(String empId) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final db = ref.read(firestoreProvider);

      await db.collection('employees').doc(empId).delete();

      state = state.copyWith(isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return false;
    }
  }
}

final employeeNotifierProvider =
NotifierProvider<EmployeeNotifier, EmployeeState>(
  EmployeeNotifier.new,
);