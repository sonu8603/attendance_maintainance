import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/provider/auth_provider.dart';
import '../../../core/provider/firebase_provider.dart';


/// Current logged-in employee data
final currentEmployeeProvider =
Provider<Map<String, dynamic>>((ref) {

  final authState = ref.watch(authProvider);

  return authState.employeeData ?? {};
});


/// Get Admin Email Dynamically
final adminEmailProvider =
FutureProvider<String>((ref) async {

  final db = ref.read(firestoreProvider);

  final snap = await db
      .collection('employees')
      .where('role', isEqualTo: 'admin')
      .limit(1)
      .get();

  if (snap.docs.isEmpty) {
    return '';
  }

  return snap.docs.first.data()['email'] ?? '';
});


/// Get Supervisor Email Dynamically
final supervisorEmailProvider =
FutureProvider<String>((ref) async {

  final db = ref.read(firestoreProvider);

  final snap = await db
      .collection('employees')
      .where('role', isEqualTo: 'supervisor')
      .limit(1)
      .get();

  if (snap.docs.isEmpty) {
    return '';
  }

  return snap.docs.first.data()['email'] ?? '';
});