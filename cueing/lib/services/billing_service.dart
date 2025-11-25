import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:cloud_firestore/cloud_firestore.dart';

class BillSession {
  final String id;
  final String userId;
  final String courtId;
  final int bookedMinutes;
  final int actualMinutes;
  final DateTime startTime;
  final DateTime endTime;
  final int bookedAmount;
  final int overtimeCharge;
  final int totalAmount;
  final bool isPaid;
  final DateTime createdAt;

  BillSession({
    required this.id,
    required this.userId,
    required this.courtId,
    required this.bookedMinutes,
    required this.actualMinutes,
    required this.startTime,
    required this.endTime,
    required this.bookedAmount,
    required this.overtimeCharge,
    required this.totalAmount,
    this.isPaid = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'courtId': courtId,
        'bookedMinutes': bookedMinutes,
        'actualMinutes': actualMinutes,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'bookedAmount': bookedAmount,
        'overtimeCharge': overtimeCharge,
        'totalAmount': totalAmount,
        'isPaid': isPaid,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BillSession.fromJson(Map<String, dynamic> json) => BillSession(
        id: json['id'] ?? '',
        userId: json['userId'] ?? '',
        courtId: json['courtId'] ?? '',
        bookedMinutes: json['bookedMinutes'] ?? 0,
        actualMinutes: json['actualMinutes'] ?? 0,
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        bookedAmount: json['bookedAmount'] ?? 0,
        overtimeCharge: json['overtimeCharge'] ?? 0,
        totalAmount: json['totalAmount'] ?? 0,
        isPaid: json['isPaid'] ?? false,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      );

  factory BillSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BillSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      courtId: data['courtId'] ?? '',
      bookedMinutes: data['bookedMinutes'] ?? 0,
      actualMinutes: data['actualMinutes'] ?? 0,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      bookedAmount: data['bookedAmount'] ?? 0,
      overtimeCharge: data['overtimeCharge'] ?? 0,
      totalAmount: data['totalAmount'] ?? 0,
      isPaid: data['isPaid'] ?? false,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'courtId': courtId,
        'bookedMinutes': bookedMinutes,
        'actualMinutes': actualMinutes,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'bookedAmount': bookedAmount,
        'overtimeCharge': overtimeCharge,
        'totalAmount': totalAmount,
        'isPaid': isPaid,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  bool get _useFirestore => Firebase.apps.isNotEmpty;
  final Map<String, List<BillSession>> _localSessions = {};

  // Billing rate constants
  static const int RATE_PER_INCREMENT = 50; // ₱50
  static const int TIME_INCREMENT_MINUTES = 30; // 30 minutes
  static const int GRACE_PERIOD_MINUTES = 5; // 5-minute grace period for overtime

  /// Calculate charge based on minutes
  int calculateCharge(int minutes) {
    if (minutes <= 0) return 0;
    final increments = (minutes / TIME_INCREMENT_MINUTES).ceil();
    final charge = increments * RATE_PER_INCREMENT;
    debugPrint('BillingService.calculateCharge: $minutes min = $increments increments = ₱$charge');
    return charge;
  }

  /// Calculate overtime charge with grace period
  int calculateOvertimeCharge(int bookedMinutes, int actualMinutes) {
    final overtimeMinutes = actualMinutes > bookedMinutes 
      ? actualMinutes - bookedMinutes 
      : 0;
    
    if (overtimeMinutes <= 0) {
      debugPrint('BillingService.calculateOvertimeCharge: No overtime');
      return 0;
    }

    // Apply grace period
    if (overtimeMinutes <= GRACE_PERIOD_MINUTES) {
      debugPrint('BillingService.calculateOvertimeCharge: Within grace period ($overtimeMinutes min)');
      return 0;
    }

    // Charge for overtime beyond grace period
    final chargeableMinutes = overtimeMinutes - GRACE_PERIOD_MINUTES;
    final increments = (chargeableMinutes / TIME_INCREMENT_MINUTES).ceil();
    final charge = increments * RATE_PER_INCREMENT;
    
    debugPrint('BillingService.calculateOvertimeCharge: $overtimeMinutes min overtime, $chargeableMinutes chargeable = ₱$charge');
    return charge;
  }

  /// Create a new bill session when a game ends
  Future<String> createBillSession({
    required String userId,
    required String courtId,
    required int bookedMinutes,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    debugPrint('=== BillingService.createBillSession START ===');
    debugPrint('userId: $userId');
    debugPrint('courtId: $courtId');
    debugPrint('bookedMinutes: $bookedMinutes');
    debugPrint('startTime: $startTime');
    debugPrint('endTime: $endTime');

    // Calculate actual minutes played
    final actualMinutes = endTime.difference(startTime).inMinutes;
    debugPrint('actualMinutes calculated: $actualMinutes');
    
    // Calculate charges
    final bookedAmount = calculateCharge(bookedMinutes);
    debugPrint('bookedAmount: ₱$bookedAmount');
    
    final overtimeCharge = calculateOvertimeCharge(bookedMinutes, actualMinutes);
    debugPrint('overtimeCharge: ₱$overtimeCharge');
    
    final totalAmount = bookedAmount + overtimeCharge;
    debugPrint('totalAmount: ₱$totalAmount');

    if (_useFirestore) {
      try {
        final session = BillSession(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          userId: userId,
          courtId: courtId,
          bookedMinutes: bookedMinutes,
          actualMinutes: actualMinutes,
          startTime: startTime,
          endTime: endTime,
          bookedAmount: bookedAmount,
          overtimeCharge: overtimeCharge,
          totalAmount: totalAmount,
          isPaid: false,
        );

        debugPrint('Creating Firestore document...');
        final docRef = await FirebaseFirestore.instance
            .collection('billingSessions')
            .add(session.toFirestore());
        
        debugPrint('Firestore document created with ID: ${docRef.id}');
        debugPrint('=== BillingService.createBillSession END (Firestore) ===');
        return docRef.id;
      } catch (e) {
        debugPrint('ERROR creating Firestore billing session: $e');
        debugPrint('=== BillingService.createBillSession FAILED ===');
        rethrow;
      }
    } else {
      // Local storage
      final session = BillSession(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        userId: userId,
        courtId: courtId,
        bookedMinutes: bookedMinutes,
        actualMinutes: actualMinutes,
        startTime: startTime,
        endTime: endTime,
        bookedAmount: bookedAmount,
        overtimeCharge: overtimeCharge,
        totalAmount: totalAmount,
        isPaid: false,
      );

      debugPrint('Storing session locally...');
      _localSessions.putIfAbsent(userId, () => []);
      _localSessions[userId]!.add(session);
      
      debugPrint('Local session stored. Total sessions for $userId: ${_localSessions[userId]!.length}');
      
      // Notify listeners
      _notifySessionChange(userId);
      _notifyAllSessionsChange();
      
      debugPrint('=== BillingService.createBillSession END (Local) ===');
      return session.id;
    }
  }

  /// Get all unpaid sessions for a user today
  Future<List<BillSession>> getUnpaidSessionsToday(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    if (_useFirestore) {
      final snapshot = await FirebaseFirestore.instance
          .collection('billingSessions')
          .where('userId', isEqualTo: userId)
          .where('isPaid', isEqualTo: false)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => BillSession.fromFirestore(doc)).toList();
    } else {
      final sessions = _localSessions[userId] ?? [];
      return sessions.where((s) {
        return !s.isPaid && 
               s.createdAt.isAfter(startOfDay) && 
               s.createdAt.isBefore(endOfDay);
      }).toList();
    }
  }

  /// Get all unpaid sessions for a user (all time)
  Future<List<BillSession>> getAllUnpaidSessions(String userId) async {
    debugPrint('BillingService.getAllUnpaidSessions for userId: $userId');
    
    if (_useFirestore) {
      debugPrint('Querying Firestore for unpaid sessions...');
      final snapshot = await FirebaseFirestore.instance
          .collection('billingSessions')
          .where('userId', isEqualTo: userId)
          .where('isPaid', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final sessions = snapshot.docs.map((doc) => BillSession.fromFirestore(doc)).toList();
      debugPrint('Found ${sessions.length} unpaid sessions in Firestore');
      return sessions;
    } else {
      final sessions = _localSessions[userId] ?? [];
      final unpaid = sessions.where((s) => !s.isPaid).toList();
      debugPrint('Found ${unpaid.length} unpaid sessions in local storage');
      return unpaid;
    }
  }

  // Local stream controllers for each user
  final Map<String, StreamController<List<BillSession>>> _userStreamControllers = {};

  /// Get or create stream controller for a user
  StreamController<List<BillSession>> _getUserStreamController(String userId) {
    if (!_userStreamControllers.containsKey(userId)) {
      _userStreamControllers[userId] = StreamController<List<BillSession>>.broadcast();
    }
    return _userStreamControllers[userId]!;
  }

  /// Notify listeners about session changes (local only)
  void _notifySessionChange(String userId) {
    if (_useFirestore) return; // Firestore handles its own notifications
    
    final controller = _getUserStreamController(userId);
    final sessions = _localSessions[userId] ?? [];
    final unpaid = sessions.where((s) => !s.isPaid).toList();
    debugPrint('Notifying stream: ${unpaid.length} unpaid sessions for $userId');
    controller.add(unpaid);
  }

  /// Stream unpaid sessions for real-time updates
  Stream<List<BillSession>> streamUnpaidSessions(String userId) {
    debugPrint('BillingService.streamUnpaidSessions called for userId: $userId');
    
    if (_useFirestore) {
      debugPrint('Returning Firestore stream');
      return FirebaseFirestore.instance
          .collection('billingSessions')
          .where('userId', isEqualTo: userId)
          .where('isPaid', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            final sessions = snapshot.docs.map((doc) => BillSession.fromFirestore(doc)).toList();
            debugPrint('Firestore stream emitted ${sessions.length} sessions');
            return sessions;
          });
    } else {
      debugPrint('Returning local stream');
      // For local, use persistent broadcast stream controller
      final controller = _getUserStreamController(userId);
      
      // Immediately emit current state
      final sessions = _localSessions[userId] ?? [];
      final unpaid = sessions.where((s) => !s.isPaid).toList();
      debugPrint('Local stream initial emit: ${unpaid.length} sessions');
      Future.microtask(() => controller.add(unpaid));

      return controller.stream;
    }
  }

  /// Calculate total unpaid amount
  int calculateTotalUnpaid(List<BillSession> sessions) {
    final total = sessions.fold(0, (sum, session) => sum + session.totalAmount);
    debugPrint('BillingService.calculateTotalUnpaid: ${sessions.length} sessions = ₱$total');
    return total;
  }

  // Global stream controller for admin view
  StreamController<Map<String, List<BillSession>>>? _allSessionsController;

  StreamController<Map<String, List<BillSession>>> _getAllSessionsController() {
    _allSessionsController ??= StreamController<Map<String, List<BillSession>>>.broadcast();
    return _allSessionsController!;
  }

  void _notifyAllSessionsChange() {
    if (_useFirestore) return;
    
    final controller = _getAllSessionsController();
    final Map<String, List<BillSession>> billsByUser = {};
    
    _localSessions.forEach((userId, sessions) {
      final unpaid = sessions.where((s) => !s.isPaid).toList();
      if (unpaid.isNotEmpty) {
        billsByUser[userId] = unpaid;
      }
    });
    
    debugPrint('Notifying all sessions stream: ${billsByUser.length} users with bills');
    controller.add(billsByUser);
  }

  /// Mark sessions as paid (used by admin)
  Future<void> markAsPaid(List<String> sessionIds, String userId) async {
    debugPrint('BillingService.markAsPaid: ${sessionIds.length} sessions for $userId');
    
    if (_useFirestore) {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final id in sessionIds) {
        final docRef = FirebaseFirestore.instance.collection('billingSessions').doc(id);
        batch.update(docRef, {'isPaid': true});
      }
      
      await batch.commit();
      debugPrint('Firestore batch update completed');
    } else {
      final sessions = _localSessions[userId] ?? [];
      for (var i = 0; i < sessions.length; i++) {
        if (sessionIds.contains(sessions[i].id)) {
          sessions[i] = BillSession(
            id: sessions[i].id,
            userId: sessions[i].userId,
            courtId: sessions[i].courtId,
            bookedMinutes: sessions[i].bookedMinutes,
            actualMinutes: sessions[i].actualMinutes,
            startTime: sessions[i].startTime,
            endTime: sessions[i].endTime,
            bookedAmount: sessions[i].bookedAmount,
            overtimeCharge: sessions[i].overtimeCharge,
            totalAmount: sessions[i].totalAmount,
            isPaid: true,
            createdAt: sessions[i].createdAt,
          );
        }
      }
      
      debugPrint('Local sessions marked as paid');
      // Notify listeners
      _notifySessionChange(userId);
      _notifyAllSessionsChange();
    }
  }

  /// Get all users with unpaid bills (for admin)
  Future<Map<String, List<BillSession>>> getAllUnpaidBillsByUser() async {
    debugPrint('BillingService.getAllUnpaidBillsByUser called');
    
    if (_useFirestore) {
      final snapshot = await FirebaseFirestore.instance
          .collection('billingSessions')
          .where('isPaid', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final Map<String, List<BillSession>> billsByUser = {};
      
      for (final doc in snapshot.docs) {
        final session = BillSession.fromFirestore(doc);
        billsByUser.putIfAbsent(session.userId, () => []);
        billsByUser[session.userId]!.add(session);
      }
      
      debugPrint('Found ${billsByUser.length} users with unpaid bills (Firestore)');
      return billsByUser;
    } else {
      final Map<String, List<BillSession>> billsByUser = {};
      
      _localSessions.forEach((userId, sessions) {
        final unpaid = sessions.where((s) => !s.isPaid).toList();
        if (unpaid.isNotEmpty) {
          billsByUser[userId] = unpaid;
        }
      });
      
      debugPrint('Found ${billsByUser.length} users with unpaid bills (Local)');
      return billsByUser;
    }
  }

  /// Stream all unpaid bills for admin
  Stream<Map<String, List<BillSession>>> streamAllUnpaidBills() {
    debugPrint('BillingService.streamAllUnpaidBills called');
    
    if (_useFirestore) {
      return FirebaseFirestore.instance
          .collection('billingSessions')
          .where('isPaid', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final Map<String, List<BillSession>> billsByUser = {};
        
        for (final doc in snapshot.docs) {
          final session = BillSession.fromFirestore(doc);
          billsByUser.putIfAbsent(session.userId, () => []);
          billsByUser[session.userId]!.add(session);
        }
        
        debugPrint('Admin stream emitted: ${billsByUser.length} users with bills');
        return billsByUser;
      });
    } else {
      final controller = _getAllSessionsController();
      
      // Immediately emit current state
      final Map<String, List<BillSession>> billsByUser = {};
      _localSessions.forEach((userId, sessions) {
        final unpaid = sessions.where((s) => !s.isPaid).toList();
        if (unpaid.isNotEmpty) {
          billsByUser[userId] = unpaid;
        }
      });
      debugPrint('Admin stream initial emit: ${billsByUser.length} users with bills (Local)');
      Future.microtask(() => controller.add(billsByUser));

      return controller.stream;
    }
  }
}