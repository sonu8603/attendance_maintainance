import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/provider/firebase_provider.dart';

// 📅 1. सभी एम्प्लॉईज का लाइव स्ट्रीम प्रोवाइडर
final employeesStreamProvider =
StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('employees')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => doc.data()).toList());
});

// 🛠️ 2. स्टेट क्लास (सिंपल, कड़क और यूआई फ्रेंडली)
class EmployeeState {
  final bool isLoading;
  final String? error;

  const EmployeeState({
    this.isLoading = false,
    this.error,
  });

  EmployeeState copyWith({bool? isLoading, String? error}) {
    return EmployeeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// 🚀 3. नया नॉटिफ़ायर (Riverpod 2.x Notifier एप्रोच)
class EmployeeNotifier extends Notifier<EmployeeState> {
  @override
  EmployeeState build() => const EmployeeState();

  // 🆔 अगला एम्प्लॉई आईडी ऑटो-जेनरेट करने का इंटरनल फंक्शन
  Future<String> generateEmployeeId() async {
    // 🎯 यूआई से db पास करने की ज़रूरत नहीं, सीधे अंदर ही रीड कर लिया
    final db = ref.read(firestoreProvider);

    final snap = await db
        .collection('employees')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get(const GetOptions(source: Source.server)); // लाइव सर्वर से चेक करना सेफ है

    if (snap.docs.isEmpty) return 'EMP001';
    final lastId = snap.docs.first.id;
    final num = int.tryParse(lastId.replaceAll('EMP', '')) ?? 0;
    return 'EMP${(num + 1).toString().padLeft(3, '0')}';
  }

  // ➕ एम्प्लॉई ऐड करने का फंक्शन
  Future<String?> addEmployee({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String role,
    required String siteId,
    required String createdBy,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = ref.read(firestoreProvider);
      final empId = await generateEmployeeId(); // बिना db पास किए कॉल होगा

      await db.collection('employees').doc(empId).set({
        'employeeId': empId,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'role': role,
        'siteId': siteId,
        'status': 'active',
        'authUid': '',
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(isLoading: false);
      return empId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  // 📝 एम्प्लॉई का डेटा अपडेट करने का फंक्शन
  Future<bool> updateEmployee(String empId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = ref.read(firestoreProvider);
      await db.collection('employees').doc(empId).update(data);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ❌ एम्प्लॉई डिलीट करने का फंक्शन
  Future<bool> deleteEmployee(String empId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = ref.read(firestoreProvider);
      await db.collection('employees').doc(empId).delete();

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

// 🎯 4. फाइनल नॉटिफ़ायर प्रोवाइडर (बिना किसी बाहरी पैकेज के)
final employeeNotifierProvider =
NotifierProvider<EmployeeNotifier, EmployeeState>(
  EmployeeNotifier.new,
);


final employeeSearchProvider = StateProvider<String>((ref) => '');