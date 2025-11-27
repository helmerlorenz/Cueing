import 'dart:async';
import 'package:flutter/material.dart';
import '../services/billing_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class TimerScreen extends StatefulWidget {
  final int minutes;
  final String courtId;   // ✅ no default

  const TimerScreen({
    super.key, 
    required this.minutes,
    required this.courtId,   // ✅ must be passed
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late int _remainingSeconds;
  late DateTime _startTime;
  Timer? _timer;
  bool _isRunning = false;
  bool _sessionEnded = false;
  final _billingService = BillingService();
  String _userId = 'guest';

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.minutes * 60;
    _startTime = DateTime.now();
    _loadUser();

    debugPrint('=== TimerScreen initialized ===');
    debugPrint('Booked minutes: ${widget.minutes}');
    debugPrint('Court: ${widget.courtId}');   // ✅ shows correct court
    debugPrint('Start time: $_startTime');
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUser();
    setState(() {
      _userId = user?.username ?? 'guest';
    });
    debugPrint('User loaded: $_userId');
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    debugPrint('Timer started');
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        setState(() => _isRunning = false);
        debugPrint('Timer reached zero - auto ending session');
        _endSession();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    debugPrint('Timer paused');
  }

  Future<void> _endSession() async {
    if (_sessionEnded) return;
    setState(() => _sessionEnded = true);
    _timer?.cancel();
    
    final endTime = DateTime.now();
    debugPrint('=== Ending Session ===');
    debugPrint('User ID: $_userId');
    debugPrint('Court ID: ${widget.courtId}');   // ✅ correct court
    debugPrint('Booked minutes: ${widget.minutes}');
    debugPrint('Start time: $_startTime');
    debugPrint('End time: $endTime');

    // Create billing session
    try {
      final sessionId = await _billingService.createBillSession(
        userId: _userId,
        courtId: widget.courtId,   // ✅ pass actual court
        bookedMinutes: widget.minutes,
        startTime: _startTime,
        endTime: endTime,
      );
      debugPrint('Billing session created successfully! ID: $sessionId');

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog if shown

      // Navigate to bills or courts tab
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen(initialTab: 2)),
        (route) => false,
      );
    } catch (e) {
      debugPrint('ERROR creating billing session: $e');
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  String _formatTime() {
    final hours = (_remainingSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('Court: ${widget.courtId}'),   // ✅ shows correct court
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'TIMER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: Text(
                    _formatTime(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _sessionEnded ? null : (_isRunning ? _stopTimer : _startTimer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 24),
                    const SizedBox(width: 8),
                    Text(_isRunning ? 'PAUSE' : 'START'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _sessionEnded ? null : _endSession,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 2),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('End Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
