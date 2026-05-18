import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/provider/firebase_provider.dart';


// Current employee profile — realtime
final myProfileProvider =
StreamProvider<Map<String, dynamic>?>((ref) {
  final db = ref.watch(firestoreProvider);
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;

  if (uid == null) return Stream.value(null);

  return db
      .collection('employees')
      .where('authUid', isEqualTo: uid)
      .limit(1)
      .snapshots()
      .map((snap) {
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  });
});