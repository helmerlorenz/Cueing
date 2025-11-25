import 'dart:async';
import 'package:flutter/material.dart';
import '../services/billing_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class TimerScreen extends StatefulWidget {
  final int minutes;
  final String courtId;
  
  const TimerScreen({
    super.key, 
    required this.minutes,
    this.courtId = 'Court 1',
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
    debugPrint('Court: ${widget.courtId}');
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
    // Prevent multiple calls
    if (_sessionEnded) {
      debugPrint('Session already ended, skipping');
      return;
    }
    
    setState(() => _sessionEnded = true);
    _timer?.cancel();
    
    final endTime = DateTime.now();
    
    debugPrint('=== Ending Session ===');
    debugPrint('User ID: $_userId');
    debugPrint('Court ID: ${widget.courtId}');
    debugPrint('Booked minutes: ${widget.minutes}');
    debugPrint('Start time: $_startTime');
    debugPrint('End time: $endTime');
    debugPrint('Duration: ${endTime.difference(_startTime).inMinutes} minutes');
    
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );
    
    // Create billing session
    try {
      debugPrint('Creating billing session...');
      final sessionId = await _billingService.createBillSession(
        userId: _userId,
        courtId: widget.courtId,
        bookedMinutes: widget.minutes,
        startTime: _startTime,
        endTime: endTime,
      );
      
      debugPrint('Billing session created successfully! ID: $sessionId');
      
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success with bill details
      final actualMinutes = endTime.difference(_startTime).inMinutes;
      final bookedAmount = _billingService.calculateCharge(widget.minutes);
      final overtimeCharge = _billingService.calculateOvertimeCharge(
        widget.minutes, 
        actualMinutes
      );
      final totalAmount = bookedAmount + overtimeCharge;
      
      final shouldViewBill = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Session Complete!',
            style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your session has been added to your bill.',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2D2D2D)),
                ),
                child: Column(
                  children: [
                    _buildBillRow('Court', widget.courtId, isHeader: true),
                    const Divider(color: Color(0xFF2D2D2D), height: 16),
                    _buildBillRow('Booked Time', '${widget.minutes} min'),
                    _buildBillRow('Actual Time', '$actualMinutes min'),
                    const SizedBox(height: 8),
                    _buildBillRow('Booked Amount', '₱$bookedAmount'),
                    if (overtimeCharge > 0)
                      _buildBillRow(
                        'Overtime Charge', 
                        '₱$overtimeCharge',
                        color: Colors.orange,
                      ),
                    const Divider(color: Color(0xFF2D2D2D), height: 16),
                    _buildBillRow(
                      'Total', 
                      '₱$totalAmount',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please settle at the counter.',
                style: TextStyle(
                  color: Colors.orange[300],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Later',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text(
                'View Bills',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (shouldViewBill == true) {
        // Navigate to home screen with billing tab selected (index 2)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(initialTab: 2),
          ),
          (route) => false,
        );
      } else {
        // Navigate to home screen with courts tab (index 0)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(initialTab: 0),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('ERROR creating billing session: $e');
      
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Error',
            style: TextStyle(color: Colors.red),
          ),
          content: Text(
            'Failed to create billing session: $e\n\nPlease inform the staff.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(initialTab: 0),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBillRow(
    String label, 
    String value, 
    {bool isHeader = false, bool isTotal = false, Color? color}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color ?? (isTotal ? const Color(0xFF10B981) : Colors.white70),
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? (isTotal ? const Color(0xFF10B981) : Colors.white),
              fontSize: isTotal ? 18 : (isHeader ? 14 : 13),
              fontWeight: isTotal || isHeader ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _endEarly() async {
    if (_sessionEnded) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('End Session Early?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to end this session now? This will add the session to your bill.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('End Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      if (_isRunning) {
        _stopTimer();
      }
      await _endSession();
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
    return WillPopScope(
      onWillPop: () async {
        // Don't allow back button - must use End Session button
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please use "End Session" button to finish'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.courtId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'TIMER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LIVE TIME',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _remainingSeconds <= 300
                            ? Colors.red.withOpacity(0.2)
                            : const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _remainingSeconds <= 300 ? Icons.warning_amber : Icons.schedule,
                            size: 14,
                            color: _remainingSeconds <= 300 ? Colors.red : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _remainingSeconds <= 300 ? 'Ending Soon' : 'In Progress',
                            style: TextStyle(
                              color: _remainingSeconds <= 300 ? Colors.red : const Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _remainingSeconds <= 300
                              ? Colors.red.withOpacity(0.1)
                              : const Color(0xFF10B981).withOpacity(0.1),
                          _remainingSeconds <= 300
                              ? Colors.red.withOpacity(0.05)
                              : const Color(0xFF10B981).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _remainingSeconds <= 300
                            ? Colors.red.withOpacity(0.3)
                            : const Color(0xFF10B981).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTime(),
                            style: TextStyle(
                              color: _remainingSeconds <= 300 ? Colors.red : Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              height: 1,
                            ),
                          ),
                          if (_remainingSeconds <= 300) ...[
                            const SizedBox(height: 16),
                            Text(
                              _remainingSeconds <= 0 ? 'Time\'s Up!' : 'Almost done',
                              style: TextStyle(
                                color: Colors.red[300],
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                      Text(
                        _isRunning ? 'PAUSE' : 'START',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _sessionEnded ? null : _endEarly,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 2),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stop, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'End Session',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}