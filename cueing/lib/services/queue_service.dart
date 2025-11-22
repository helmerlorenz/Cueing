import 'dart:async';

class QueueEntry {
  final String id;
  final String userId;
  final DateTime joinedAt;

  QueueEntry({required this.id, required this.userId, DateTime? joinedAt}) : joinedAt = joinedAt ?? DateTime.now();
}

/// A very small in-memory queue service used for UI prototyping.
/// It supports joining a court queue, leaving, and streaming position updates.
// TODO: This local QueueService is an in-memory prototype used for UI development.
// To migrate to Firebase/Firestore:
// 1. Create a new file `lib/services/firestore_queue_service.dart` implementing the same
//    public API used throughout the app: joinQueue, leaveQueue, popNext, queueLength,
//    streamPosition, findEntry, listUserIds, etc.
// 2. Implement Firestore operations using a `courts/{courtId}/queue` subcollection.
//    - joinQueue should add a document with fields: userId, username, joinedAt, durationMinutes.
//    - streamPosition should read snapshots and compute ordered positions by `joinedAt`.
//    - popNext should use a transaction or callable Cloud Function to ensure atomicity when
//      moving the first queued item to active/removed.
// 3. Swap usages by returning an instance of FirestoreQueueService from a factory or
//    injecting it where needed. Prefer keeping the same method signatures to minimize UI changes.
// 4. Add Firestore security rules and test with the Firebase Emulator Suite.

class QueueService {
  static final QueueService _instance = QueueService._internal();
  factory QueueService() => _instance;
  QueueService._internal();

  final Map<String, List<QueueEntry>> _queues = {};
  final Map<String, StreamController<int>> _positionControllers = {};

  // Ensure queue exists for a court
  void _ensureCourt(String courtId) {
    _queues.putIfAbsent(courtId, () => []);
    _positionControllers.putIfAbsent(courtId, () => StreamController<int>.broadcast());
  }

  /// Join queue for a court. Returns the created entry id.
  String joinQueue(String courtId, String userId) {
    _ensureCourt(courtId);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final entry = QueueEntry(id: id, userId: userId);
    _queues[courtId]!.add(entry);
    _notifyCourt(courtId);
    return id;
  }

  /// Leave queue by entry id.
  void leaveQueue(String courtId, String entryId) {
    _ensureCourt(courtId);
    _queues[courtId]!.removeWhere((e) => e.id == entryId);
    _notifyCourt(courtId);
  }

  /// Pop the first entry (admin action: start next game)
  QueueEntry? popNext(String courtId) {
    _ensureCourt(courtId);
    if (_queues[courtId]!.isEmpty) return null;
    final e = _queues[courtId]!.removeAt(0);
    _notifyCourt(courtId);
    return e;
  }

  /// Get the current queue length.
  int queueLength(String courtId) {
    _ensureCourt(courtId);
    return _queues[courtId]!.length;
  }

  /// Stream of the position (0-based count of people ahead) for a given entry id.
  /// If entry is removed it will emit -1.
  Stream<int> streamPosition(String courtId, String entryId) {
    _ensureCourt(courtId);
    final controller = _positionControllers[courtId]!;

    // Immediately emit current position and then rely on broadcasts
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
    // broadcast the queue length so listeners can recalc positions
    controller.add(_queues[courtId]!.length);
  }

  /// For UI: list current user ids in queue for a court
  List<String> listUserIds(String courtId) {
    _ensureCourt(courtId);
    return _queues[courtId]!.map((e) => e.userId).toList();
  }

  /// Find the queue entry for a given user on a court (or null)
  QueueEntry? findEntry(String courtId, String userId) {
    _ensureCourt(courtId);
    for (final e in _queues[courtId]!) {
      if (e.userId == userId) return e;
    }
    return null;
  }
}
