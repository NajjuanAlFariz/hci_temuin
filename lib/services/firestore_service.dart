import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ============================================================
  /// AUTH USER
  /// ============================================================
  User? get currentUser => _auth.currentUser;

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
    final user = currentUser;
    if (user == null) throw Exception('User belum login');

    await _db.collection('lost_items').add({
      'name': name,
      'category': category,
      'location': location,
      'description': description,
      'image_url': imageUrl,
      'user_id': user.uid,
      'status': 'active',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// ============================================================
  /// CREATE - LAPORAN BARANG TEMUAN
  /// ============================================================
  Future<void> createFoundReport({
    required String name,
    required String category,
    required String location,
    String? imageUrl,
  }) async {
    final user = currentUser;
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

  /// ============================================================
  /// GET LIST DATA
  /// ============================================================
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

  /// ============================================================
  /// UPDATE STATUS LAPORAN
  /// ============================================================
  Future<void> updateReportStatus({
    required String collection,
    required String docId,
    required String status,
  }) async {
    await _db.collection(collection).doc(docId).update({
      'status': status,
    });
  }

  /// ============================================================
  /// REQUEST OWNERSHIP VERIFICATION (→ BUAT NOTIFIKASI)
  /// ============================================================
  Future<void> requestOwnershipVerification({
    required String reportId,
    required String reportType, // lost | found
    required String description,
    required String targetUserId,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User belum login');

    final verificationRef =
        await _db.collection('ownership_verifications').add({
      'report_id': reportId,
      'report_type': reportType,
      'description': description,

      // pengaju (pemilik barang)
      'requester_user_id': user.uid,
      'requester_name':
          user.displayName ?? user.email!.split('@').first,

      // penerima (penemu barang)
      'target_user_id': targetUserId,

      'status': 'pending', // pending | accepted | rejected
      'read': false,
      'created_at': FieldValue.serverTimestamp(),
    });

    // ⬇️ NOTIFIKASI UNTUK TARGET USER
    await _db.collection('notifications').add({
      'user_id': targetUserId,
      'type': 'ownership_request',
      'ref_id': verificationRef.id,
      'title': 'Verifikasi Kepemilikan',
      'message': 'Ada permintaan verifikasi barang',
      'read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// ============================================================
  /// RESPON VERIFIKASI (ACCEPT / REJECT)
  /// ============================================================
  Future<void> respondOwnershipVerification({
    required String verificationId,
    required bool accepted,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User belum login');

    final status = accepted ? 'accepted' : 'rejected';

    final ref =
        _db.collection('ownership_verifications').doc(verificationId);

    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final String requesterId = data['requester_user_id'];

    // UPDATE STATUS
    await ref.update({
      'status': status,
      'read': true,
    });

    // ⬇️ NOTIFIKASI BALIK KE REQUESTER
    await _db.collection('notifications').add({
      'user_id': requesterId,
      'type': 'ownership_response',
      'ref_id': verificationId,
      'title': accepted
          ? 'Verifikasi Diterima'
          : 'Verifikasi Ditolak',
      'message': accepted
          ? 'Permintaan kepemilikan diterima'
          : 'Permintaan kepemilikan ditolak',
      'read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// ============================================================
  /// NOTIFICATIONS
  /// ============================================================
  Stream<QuerySnapshot> getUserNotifications() {
    final user = currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _db
        .collection('notifications')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Stream<int> getUnreadNotificationCount() {
    final user = currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _db
        .collection('notifications')
        .where('user_id', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }
}
