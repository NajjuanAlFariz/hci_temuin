import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ============================================================
  /// CREATE - LAPORAN BARANG HILANG
  /// ============================================================
  Future<void> createLostReport({
    required String name,
    required String category,
    required String location,
    required String description,
    required String imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User belum login');

    await _db.collection('lost_items').add({
      'name': name,
      'category': category,
      'location': location,
      'description': description,
      'image_url': imageUrl,
      'user_id': user.uid,
      'status': 'active', // active | resolved
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createFoundReport({
    required String name,
    required String category,
    required String location,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User belum login');

    await _db.collection('found_items').add({
      'name': name,
      'category': category,
      'location': location,
      'image_url': imageUrl,
      'user_id': user.uid,
      'status': 'active',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getLostItems() {
    return _db
        .collection('lost_items')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getFoundItems() {
    return _db
        .collection('found_items')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<void> updateReportStatus({
    required String collection,
    required String docId,
    required String status, 
  }) async {
    await _db.collection(collection).doc(docId).update({
      'status': status,
    });
  }
}
