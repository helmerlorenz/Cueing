import 'dart:async';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:cloud_firestore/cloud_firestore.dart';

class QueueEntry {
  final String id;
  final String userId;
  final DateTime joinedAt;

  QueueEntry({
    required this.id,
    required this.userId,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();
}

/// QueueService: hybrid implementation.
/// Uses Firestore when Firebase is initialized, otherwise falls back to in‑memory prototype.
class QueueService {
  static final QueueService _instance = QueueService._internal();
  factory QueueService() => _instance;
  QueueService._internal();

  final Map<String, List<QueueEntry>> _queues = {};
  final Map<String, StreamController<int>> _positionControllers = {};

  bool get _useFirestore => Firebase.apps.isNotEmpty;

  void _ensureCourt(String courtId) {
    _queues.putIfAbsent(courtId, () => []);
    _positionControllers.putIfAbsent(courtId, () => StreamController<int>.broadcast());
  }

  /// Join queue for a court. Returns the entry id.
  Future<String> joinQueue(String courtId, String userId) async {
    if (_useFirestore) {
      final col = FirebaseFirestore.instance
          .collection('courts')
          .doc(courtId)
          .collection('queue');

      // Check if user already has an entry
      final existing = await col.where('userId', isEqualTo: userId).limit(1).get();
      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id;
      }

      // Add new entry
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      await col.doc(id).set({
        'userId': userId,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      return id;
    }

    _ensureCourt(courtId);

    // Prevent duplicate in-memory entries
    final existing = _queues[courtId]!.indexWhere((e) => e.userId == userId);
    if (existing != -1) {
      return _queues[courtId]![existing].id;
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final entry = QueueEntry(id: id, userId: userId);
    _queues[courtId]!.add(entry);
    _notifyCourt(courtId);
    return id;
  }

  /// Leave queue by entry id or userId.
  Future<void> leaveQueue(String courtId, String entryId, {String? userId}) async {
    if (_useFirestore) {
      final col = FirebaseFirestore.instance
          .collection('courts')
          .doc(courtId)
          .collection('queue');

      if (userId != null) {
        final snap = await col.where('userId', isEqualTo: userId).get();
        for (final d in snap.docs) {
          await d.reference.delete();
        }
      } else {
        await col.doc(entryId).delete();
      }
      return;
    }

    _ensureCourt(courtId);
    _queues[courtId]!.removeWhere((e) => e.id == entryId || e.userId == userId);
    _notifyCourt(courtId);
  }

  /// Pop the first entry (admin action: start next game).
  Future<QueueEntry?> popNext(String courtId) async {
    if (_useFirestore) {
      final col = FirebaseFirestore.instance
          .collection('courts')
          .doc(courtId)
          .collection('queue');

      final snap = await col.orderBy('joinedAt').limit(1).get();
      if (snap.docs.isEmpty) return null;

      final d = snap.docs.first;
      await d.reference.delete();
      final data = d.data();
      return QueueEntry(
        id: d.id,
        userId: data['userId'] ?? '',
        joinedAt: (data['joinedAt'] is Timestamp)
            ? (data['joinedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    }

    _ensureCourt(courtId);
    if (_queues[courtId]!.isEmpty) return null;
    final e = _queues[courtId]!.removeAt(0);
    _notifyCourt(courtId);
    return e;
  }

  /// Get the current queue length.
  Future<int> queueLength(String courtId) async {
    if (_useFirestore) {
      final snap = await FirebaseFirestore.instance
          .collection('courts')
          .doc(courtId)
          .collection('queue')
          .get();
      return snap.docs.length;
    }

    _ensureCourt(courtId);
    return _queues[courtId]!.length;
  }

  /// Stream of the position (0-based count of people ahead) for a given entry id.
  Stream<int> streamPosition(String courtId, String entryId) {
    if (_useFirestore) {
      final controller = StreamController<int>.broadcast();
      final col = FirebaseFirestore.instance
          .collection('courts')
          .doc(courtId)
          .collection('queue')
          .orderBy('joinedAt');

      final sub = col.snapshots().listen((snap) {
        final docs = snap.docs;
        final index = docs.indexWhere((d) => d.id == entryId);
        controller.add(index == -1 ? -1 : index);
      });

      controller.onCancel = () {
        sub.cancel();
      };

      return controller.stream;
    }

    _ensureCourt(courtId);
    final controller = _positionControllers[courtId]!;

    Future.delayed(Duration.zero, () {
      final pos = _queues[courtId]!.indexWhere((e) => e.id == entryId);
      controller.add(pos == -1 ? -1 : pos);
    });

    return controller.stream.map((_) {
      final pos = _queues[courtId]!.indexWhere((e) => e.id == entryId);
      return pos == -1 ? -1 : pos;
    });
  }

  void _notifyCourt(String courtId) {
    _ensureCourt(courtId);
    final controller = _positionControllers[courtId]!;
    controller.add(_queues[courtId]!.length);
  }

  /// For UI: list current user ids in queue for a court.
  Future<List<String>> listUserIds(String courtId) async {
    if (_useFirestore) {
      final snap = await FirebaseFirestore.instance
          .collection('courts')
          .doc(courtId)
          .collection('queue')
          .get();
      return snap.docs.map((d) => d['userId'] as String).toList();
    }

    _ensureCourt(courtId);
    return _queues[courtId]!.map((e) => e.userId).toList();
  }

  /// Find the queue entry for a given user on a court (or null).
  Future<QueueEntry?> findEntry(String courtId, String userId) async {
    if (_useFirestore) {
      final snap = await FirebaseFirestore.instance
          .collection('courts')
          .doc(courtId)
          .collection('queue')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      final data = d.data();
      return QueueEntry(
        id: d.id,
        userId: data['userId'] ?? '',
        joinedAt: (data['joinedAt'] is Timestamp)
            ? (data['joinedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    }

    _ensureCourt(courtId);
    final entry = _queues[courtId]!.firstWhere(
      (e) => e.userId == userId,
      orElse: () => QueueEntry(id: '', userId: '', joinedAt: DateTime.now()),
    );
    return entry.id.isEmpty ? null : entry;
  }
}
