import 'package:flutter/material.dart';
import 'payment_screen.dart';

class GameConfirmationScreen extends StatefulWidget {
  final String table;
  const GameConfirmationScreen({super.key, required this.table});

  @override
  State<GameConfirmationScreen> createState() => _GameConfirmationScreenState();
}

class _GameConfirmationScreenState extends State<GameConfirmationScreen> {
  int hours = 1;
  int amount = 0;

  void _updateAmount(int h) {
    setState(() {
      hours = h;
      amount = h * 100; // ₱100 per hour
    });
  }

  @override
  void initState() {
    super.initState();
    _updateAmount(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: const Text('TABLE', style: TextStyle(color: Color(0xFF6B00FF), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              const Text('GAME\nCONFIRMATION', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
              const SizedBox(height: 32),
              const Text('GAME TIME', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Text('$hours HOUR', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B00FF), fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: hours > 1 ? () => _updateAmount(hours - 1) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6B00FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('- 1 HR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateAmount(hours + 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6B00FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('+ 1 HR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Text('TOTAL PAYMENT\n₱$amount', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B00FF), fontSize: 18, fontWeight: FontWeight.bold, height: 1.5)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(table: widget.table, hours: hours, amount: amount))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6B00FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Proceed to game queue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}