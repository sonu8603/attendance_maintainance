import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/provider/firebase_provider.dart';

// 📅 1. कर्मचारी की खुद की लीव रिक्वेस्ट्स का लाइव स्ट्रीम प्रोवाइडर
final myLeavesProvider =
StreamProvider.family<List<Map<String, dynamic>>, String>((ref, employeeId) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('leave_requests')
      .where('employeeId', isEqualTo: employeeId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => doc.data()).toList());
});

// 🛠️ 2. लीव स्टेट क्लास (लोडिंग और एरर संभालने के लिए)
class LeaveState {
  final bool isLoading;
  final String? error;

  const LeaveState({
    this.isLoading = false,
    this.error,
  });

  LeaveState copyWith({bool? isLoading, String? error}) {
    return LeaveState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // नया एरर सेट करने या null पास करके क्लियर करने के लिए
    );
  }
}

// 🚀 3. नया लीव नॉटिफ़ायर (Riverpod 2.x Notifier एप्रोच)
class LeaveNotifier extends Notifier<LeaveState> {
  @override
  LeaveState build() => const LeaveState();

  // 📝 छुट्टी (Leave) अप्लाई करने का फंक्शन
  Future<bool> applyLeave({
    required String employeeId,
    required String reason,
    required String fromDate,
    required String toDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = ref.read(firestoreProvider);

      await db.collection('leave_requests').add({
        'employeeId': employeeId,
        'reason': reason,
        'fromDate': fromDate,
        'toDate': toDate,
        'status': 'pending', // डिफ़ॉल्ट रूप से पेंडिंग रहेगा, एडमिन अप्रूव करेगा
        'createdAt': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(isLoading: false);
      return true; // सक्सेसफुल होने पर true देगा
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false; // फेल होने पर false देगा
    }
  }
}

// 🎯 4. फाइनल लीव नॉटिफ़ायर प्रोवाइडर
final leaveNotifierProvider =
NotifierProvider<LeaveNotifier, LeaveState>(
  LeaveNotifier.new,
);