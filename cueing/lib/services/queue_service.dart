import 'dart:async';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:cloud_firestore/cloud_firestore.dart';

class QueueEntry {
  final String id;
  final String userId;
  final DateTime joinedAt;

  QueueEntry({required this.id, required this.userId, DateTime? joinedAt}) : joinedAt = joinedAt ?? DateTime.now();
}

/// QueueService: keeps the existing in-memory prototype behavior but will
/// automatically use Firestore when Firebase is initialized for the app.
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

  /// Join queue for a court. Returns the created entry id.
  /// In Firestore mode this will create a document with a client-generated id
  /// so the method can remain synchronous for the UI.
  String joinQueue(String courtId, String userId) {
    if (_useFirestore) {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final col = FirebaseFirestore.instance.collection('courts').doc(courtId).collection('queue');
      // Fire-and-forget write using client-generated id so UI can listen to the same id.
      col.doc(id).set({'userId': userId, 'joinedAt': FieldValue.serverTimestamp()});
      return id;
    }

    _ensureCourt(courtId);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final entry = QueueEntry(id: id, userId: userId);
    _queues[courtId]!.add(entry);
    _notifyCourt(courtId);
    return id;
  }

  /// Leave queue by entry id.
  void leaveQueue(String courtId, String entryId) {
    if (_useFirestore) {
      final doc = FirebaseFirestore.instance.collection('courts').doc(courtId).collection('queue').doc(entryId);
      doc.delete();
      return;
    }

    _ensureCourt(courtId);
    _queues[courtId]!.removeWhere((e) => e.id == entryId);
    _notifyCourt(courtId);
  }

  /// Pop the first entry (admin action: start next game)
  QueueEntry? popNext(String courtId) {
    if (_useFirestore) {
      final col = FirebaseFirestore.instance.collection('courts').doc(courtId).collection('queue');
      // perform async transaction but keep method synchronous for existing callers
      col.orderBy('joinedAt').limit(1).get().then((snap) {
        if (snap.docs.isEmpty) return null;
        final d = snap.docs.first;
        d.reference.delete();
      });
      return null;
    }

    _ensureCourt(courtId);
    if (_queues[courtId]!.isEmpty) return null;
    final e = _queues[courtId]!.removeAt(0);
    _notifyCourt(courtId);
    return e;
  }

  /// Get the current queue length.
  int queueLength(String courtId) {
    if (_useFirestore) {
      // synchronous best-effort: return local cached length if available
      final local = _queues[courtId]?.length ?? 0;
      // Trigger a background fetch to update caches (UI will update via streams)
      FirebaseFirestore.instance.collection('courts').doc(courtId).collection('queue').get().then((snap) {
        _queues[courtId] = snap.docs.map((d) {
          final data = d.data();
          final userId = (data['userId'] ?? '') as String;
          DateTime? joined;
          final raw = data['joinedAt'];
          if (raw is Timestamp) {
            joined = raw.toDate();
          } else if (raw is DateTime) {
            joined = raw;
          } else {
            joined = null;
          }
          return QueueEntry(id: d.id, userId: userId, joinedAt: joined);
        }).toList();
        _notifyCourt(courtId);
      }).catchError((_) {});
      return local;
    }

    _ensureCourt(courtId);
    return _queues[courtId]!.length;
  }

  /// Stream of the position (0-based count of people ahead) for a given entry id.
  /// If entry is removed it will emit -1.
  Stream<int> streamPosition(String courtId, String entryId) {
    if (_useFirestore) {
      final controller = StreamController<int>.broadcast();
      final col = FirebaseFirestore.instance.collection('courts').doc(courtId).collection('queue').orderBy('joinedAt');

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

  /// For UI: list current user ids in queue for a court
  List<String> listUserIds(String courtId) {
    if (_useFirestore) {
      // best-effort synchronous answer from local cache
      return _queues[courtId]?.map((e) => e.userId).toList() ?? [];
    }

    _ensureCourt(courtId);
    return _queues[courtId]!.map((e) => e.userId).toList();
  }

  /// Find the queue entry for a given user on a court (or null)
  QueueEntry? findEntry(String courtId, String userId) {
    if (_useFirestore) {
      final cached = _queues[courtId];
      if (cached != null) {
        for (final e in cached) {
          if (e.userId == userId) return e;
        }
      }
      return null;
    }

    _ensureCourt(courtId);
    for (final e in _queues[courtId]!) {
      if (e.userId == userId) return e;
    }
    return null;
  }
}
