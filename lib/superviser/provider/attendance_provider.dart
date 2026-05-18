import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/provider/firebase_provider.dart';


final attendanceStreamProvider =
StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, siteId) {
      final db = ref.watch(firestoreProvider);
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      return db
          .collection('attendance')
          .where('siteId', isEqualTo: siteId)
          .where('date', isEqualTo: dateKey)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => doc.data()).toList());
    });


class AttendanceState {
  final bool isLoading;
  final String? error;

  const AttendanceState({
    this.isLoading = false,
    this.error,
  });

  AttendanceState copyWith({bool? isLoading, String? error}) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ✅ StateNotifier ki jagah Notifier use karo
class AttendanceNotifier extends Notifier<AttendanceState> {
  @override
  AttendanceState build() => const AttendanceState();

  Future<void> markAttendance({
    required String employeeId,
    required String siteId,
    required String markedBy,
    required String status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = ref.read(firestoreProvider);
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await db
          .collection('attendance')
          .doc('${dateKey}_$employeeId')
          .set({
        'employeeId': employeeId,
        'siteId': siteId,
        'date': dateKey,
        'status': status,
        'markedBy': markedBy,
        'markedAt': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}


final attendanceNotifierProvider =
NotifierProvider<AttendanceNotifier, AttendanceState>(
    AttendanceNotifier.new);