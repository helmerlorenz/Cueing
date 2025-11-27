import 'dart:async';
import 'package:flutter/material.dart';
import '../services/queue_service.dart';
import '../services/auth_service.dart';
import 'timer_screen.dart';

class QueueConfirmationScreen extends StatefulWidget {
  final String courtId;
  final int durationMinutes;

  const QueueConfirmationScreen({
    super.key,
    required this.courtId,   // ✅ required, no default
    this.durationMinutes = 60,
  });

  @override
  State<QueueConfirmationScreen> createState() => _QueueConfirmationScreenState();
}

class _QueueConfirmationScreenState extends State<QueueConfirmationScreen> {
  final _queueService = QueueService();
  String? _entryId;
  StreamSubscription<int>? _positionSub;
  int _position = -1; // -1 not in queue
  String _userId = 'guest';

  @override
  void initState() {
    super.initState();
    _initUser();
    // auto-join when screen opens for prototyping
    Future.microtask(() {
      _join();
    });
  }

  Future<void> _initUser() async {
    final user = await AuthService().getCurrentUser();
    setState(() {
      _userId = user?.username ?? 'guest';
    });
  }

  Future<void> _join() async {
    final id = await _queueService.joinQueue(widget.courtId, _userId);
    setState(() => _entryId = id);

    _positionSub?.cancel();
    _positionSub = _queueService.streamPosition(widget.courtId, id).listen((pos) {
      setState(() => _position = pos);
    });
  }

  Future<void> _leave() async {
    if (_entryId != null) {
      await _queueService.leaveQueue(widget.courtId, _entryId!, userId: _userId);
      _positionSub?.cancel();
      setState(() {
        _entryId = null;
        _position = -1;
      });
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ahead = _position <= 0 ? 0 : _position;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('Queue - ${widget.courtId}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'QUEUE STATUS',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You are in: ${widget.courtId}',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Show selected play time and price summary
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${widget.durationMinutes} min',
                        style: const TextStyle(color: Color(0xFF6B00FF), fontWeight: FontWeight.bold)),
                    Text('₱${(widget.durationMinutes ~/ 30) * 50}',
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<int>(
                future: _queueService.queueLength(widget.courtId),
                builder: (context, snapshot) {
                  final queueLen = snapshot.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text('People ahead: $ahead',
                            style: const TextStyle(color: Color(0xFF6B00FF), fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Queue length: $queueLen', style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _entryId == null ? _join : _leave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _entryId == null ? 'Join Queue' : 'Leave Queue',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              if (_entryId != null && _position == 0) ...[
                ElevatedButton(
                  onPressed: () async {
                    final id = _entryId!;
                    await _queueService.leaveQueue(widget.courtId, id, userId: _userId);
                    setState(() {
                      _entryId = null;
                      _position = -1;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TimerScreen(
                          minutes: widget.durationMinutes,
                          courtId: widget.courtId,   // ✅ pass actual selected court
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Confirm - Start Game',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to courts', style: TextStyle(color: Color(0xFF10B981))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
