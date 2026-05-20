import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/provider/firebase_provider.dart';


final myLeavesProvider =
StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, employeeId) {
      final db = ref.watch(firestoreProvider);
      return db
          .collection('leave_requests')
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => doc.data()).toList());
    });

class LeaveState {
  final bool isLoading;
  final String? error;
  const LeaveState({this.isLoading = false, this.error});

  LeaveState copyWith({bool? isLoading, String? error}) {
    return LeaveState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LeaveNotifier extends Notifier<LeaveState> {
  @override
  LeaveState build() => const LeaveState();

  Future<bool> applyLeave({
    required String employeeId,
    required String employeeName,
    required String role,
    required String siteId,
    required String siteName,
    required String supervisorId,
    required String leaveType,
    required String reason,
    required String fromDate,
    required String toDate,
    required int totalDays,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = ref.read(firestoreProvider);
      await db.collection('leave_requests').add({
        'employeeId': employeeId,
        'employeeName': employeeName,
        'role': role,
        'siteId': siteId,
        'siteName': siteName,
        'supervisorId': supervisorId,
        'leaveType': leaveType,
        'reason': reason,
        'fromDate': fromDate,
        'toDate': toDate,
        'totalDays': totalDays,
        'status': 'pending',
        'approvedBy': '',
        'approvedByRole': '',
        'approvedAt': null,
        'rejectionReason': '',
        'attachmentUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final leaveNotifierProvider =
NotifierProvider<LeaveNotifier, LeaveState>(LeaveNotifier.new);