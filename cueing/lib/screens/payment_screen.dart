import 'package:flutter/material.dart';
import 'timer_screen.dart';

class PaymentScreen extends StatelessWidget {
  final String table;
  final int hours;
  final int amount;

  const PaymentScreen({super.key, required this.table, required this.hours, required this.amount});

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
              const Text('PAYMENT', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('QR Code\nScanner', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                      const SizedBox(height: 16),
                      Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Text('TOTAL AMOUNT\n₱$amount', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B00FF), fontSize: 18, fontWeight: FontWeight.bold, height: 1.5)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TimerScreen(hours: hours))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6B00FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('PAID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}