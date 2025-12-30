import 'package:cloud_firestore/cloud_firestore.dart';

String timeAgo(Timestamp timestamp) {
  final now = DateTime.now();
  final time = timestamp.toDate();
  final diff = now.difference(time);

  if (diff.inMinutes < 1) {
    return 'Baru saja';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes} menit yang lalu';
  } else if (diff.inHours < 24) {
    return '${diff.inHours} jam yang lalu';
  } else {
    return '${diff.inDays} hari yang lalu';
  }
}
