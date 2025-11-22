import 'package:flutter/material.dart';
import '../services/queue_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _queueService = QueueService();
  final List<String> courts = List.generate(6, (i) => 'Court ${i + 1}');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0, title: const Text('Admin')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('ADMIN', style: TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Manage Queues', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: courts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = courts[i];
                    final len = _queueService.queueLength(c);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c, style: const TextStyle(color: Color(0xFF6B00FF), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('$len in queue', style: const TextStyle(color: Colors.black54)),
                          ]),
                          Row(children: [
                            ElevatedButton(
                              onPressed: len > 0 ? () { setState(() { _queueService.popNext(c); }); } : null,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                              child: const Text('Start Next'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () { setState(() { /* stub: record game */ }); },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                              child: const Text('Record'),
                            ),
                          ])
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
