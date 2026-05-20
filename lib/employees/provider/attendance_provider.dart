import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/provider/firebase_provider.dart';

// My attendance history stream
final myAttendanceProvider =
StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, employeeId) {
      final db = ref.watch(firestoreProvider);
      return db
          .collection('attendance')
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('date', descending: true)
          .limit(30) // last 30 days
          .snapshots()
          .map((snap) => snap.docs.map((doc) => doc.data()).toList());
    });

// Today's attendance for employee
final todayAttendanceProvider =
StreamProvider.family<Map<String, dynamic>?, String>(
        (ref, employeeId) {
      final db = ref.watch(firestoreProvider);
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      return db
          .collection('attendance')
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isEqualTo: dateKey)
          .limit(1)
          .snapshots()
          .map((snap) => snap.docs.isEmpty ? null : snap.docs.first.data());
    });

class AttendanceState {
  final bool isLoading;
  final String? error;
  const AttendanceState({this.isLoading = false, this.error});

  AttendanceState copyWith({bool? isLoading, String? error}) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EmployeeAttendanceNotifier extends Notifier<AttendanceState> {
  @override
  AttendanceState build() => const AttendanceState();

  Future<bool> checkIn({
    required String employeeId,
    required String employeeName,
    required String role,
    required String siteId,
    required String siteName,
    required String supervisorId,
    required double latitude,
    required double longitude,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = ref.read(firestoreProvider);
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final docId = '${dateKey}_$employeeId';

      await db.collection('attendance').doc(docId).set({
        'employeeId': employeeId,
        'employeeName': employeeName,
        'role': role,
        'siteId': siteId,
        'siteName': siteName,
        'supervisorId': supervisorId,
        'date': dateKey,
        'checkIn': FieldValue.serverTimestamp(),
        'checkOut': null,
        'checkInLocation': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'checkOutLocation': null,
        'status': 'present',
        'lateMinutes': 0,
        'workHours': 0.0,
        'isWithinRadius': true,
        'deviceInfo': 'Android',
        'createdAt': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> checkOut({
    required String employeeId,
    required double latitude,
    required double longitude,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = ref.read(firestoreProvider);
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final docId = '${dateKey}_$employeeId';

      await db.collection('attendance').doc(docId).update({
        'checkOut': FieldValue.serverTimestamp(),
        'checkOutLocation': {
          'latitude': latitude,
          'longitude': longitude,
        },
      });

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final employeeAttendanceNotifierProvider =
NotifierProvider<EmployeeAttendanceNotifier, AttendanceState>(
    EmployeeAttendanceNotifier.new);