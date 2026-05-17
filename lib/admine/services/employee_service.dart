import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeService {
  static final _db = FirebaseFirestore.instance;


  static Future<String> generateEmployeeId() async {
    final snapshot = await _db
        .collection('employees')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 'EMP001';

    final lastId = snapshot.docs.first.id; // e.g. EMP001
    final num = int.tryParse(lastId.replaceAll('EMP', '')) ?? 0;
    final newNum = (num + 1).toString().padLeft(3, '0');
    return 'EMP$newNum';
  }

  // ✅ Employee add karo
  static Future<void> addEmployee({
    required String employeeId,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String role,
    required String siteId,
    required String createdBy,
  }) async {
    await _db.collection('employees').doc(employeeId).set({
      'employeeId': employeeId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'role': role,
      'siteId': siteId,
      'status': 'active',
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ Employee list fetch karo
  static Stream<QuerySnapshot> getEmployees() {
    return _db
        .collection('employees')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ✅ Employee delete karo
  static Future<void> deleteEmployee(String employeeId) async {
    await _db.collection('employees').doc(employeeId).delete();
  }

  // ✅ Employee update karo
  static Future<void> updateEmployee(
      String employeeId, Map<String, dynamic> data) async {
    await _db.collection('employees').doc(employeeId).update(data);
  }
}