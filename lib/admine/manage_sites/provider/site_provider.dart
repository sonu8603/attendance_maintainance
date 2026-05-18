import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// 🎯 1. फायरस्टोर से लाइव साइट्स डेटा की स्ट्रीम
final sitesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('sites')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

// 🚀 2. साइट्स के ऑपरेशन्स के लिए नॉटिफ़ायर
class SiteNotifier extends Notifier<void> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void build() {}

  // ➕ नई साइट ऐड करना (कस्टम सीक्वेंशियल आईडी के साथ)
  Future<void> addSite(Map<String, dynamic> siteData) async {
    final DocumentReference counterRef = _db.collection('counters').doc('site_ids');

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      int currentCount = 0;

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        currentCount = data['current_site_count'] ?? 0;
      } else {
        // अगर काउंटर डॉक्यूमेंट नहीं है तो बनाओ
        transaction.set(counterRef, {'current_site_count': 0});
      }

      int newCount = currentCount + 1;
      transaction.update(counterRef, {'current_site_count': newCount});

      String generatedId = 'SITE${newCount.toString().padLeft(3, '0')}';

      final docRef = _db.collection('sites').doc(generatedId);
      transaction.set(docRef, {
        ...siteData,
        'siteId': generatedId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // 📝 साइट एडिट/अपडेट करना
  Future<void> updateSite(String siteId, Map<String, dynamic> updatedData) async {
    await _db.collection('sites').doc(siteId).update(updatedData);
  }


  Future<void> deleteSite(String siteId) async {
    await _db.collection('sites').doc(siteId).delete();
  }
}

// 🎯 फाइनल प्रोवाइडर
final siteNotifierProvider = NotifierProvider<SiteNotifier, void>(SiteNotifier.new);

  // site latitude and longitude
final locationLoadingProvider = StateProvider<bool>((ref) => false);

