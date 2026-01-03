import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> createUserIfNotExists({
    String? name,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'name': name ?? user.displayName ?? 'Pengguna Temuin',
        'email': user.email,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }
}
