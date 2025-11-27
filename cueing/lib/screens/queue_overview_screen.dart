import 'package:flutter/material.dart';
import '../services/queue_service.dart';
import '../services/auth_service.dart';
import 'queue_confirmation_screen.dart';

class QueueOverviewScreen extends StatefulWidget {
  const QueueOverviewScreen({super.key});

  @override
  State<QueueOverviewScreen> createState() => _QueueOverviewScreenState();
}

class _QueueOverviewScreenState extends State<QueueOverviewScreen> {
  final _queueService = QueueService();
  String _userId = 'guest';
  final List<String> courts = List.generate(6, (i) => 'Court ${i + 1}');

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUser();
    setState(() => _userId = user?.username ?? 'guest');
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
              const Text(
                'YOUR QUEUES',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Active Queues',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: courts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = courts[i];
                    return FutureBuilder<QueueEntry?>(
                      future: _queueService.findEntry(c, _userId),
                      builder: (context, snapshot) {
                        final entry = snapshot.data;
                        final inQueue = entry != null;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c,
                                    style: const TextStyle(
                                      color: Color(0xFF6B00FF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  inQueue
                                      ? const Text(
                                          'You are in queue',
                                          style: TextStyle(color: Colors.black54),
                                        )
                                      : const Text(
                                          'Not in queue',
                                          style: TextStyle(color: Colors.black54),
                                        ),
                                ],
                              ),
                              Row(
                                children: [
                                  if (inQueue) ...[
                                    StreamBuilder<int>(
                                      stream: _queueService.streamPosition(c, entry!.id),
                                      builder: (context, snap) {
                                        final posVal = snap.data ?? -1;
                                        final ahead = posVal <= 0 ? 0 : posVal;
                                        return Text(
                                          'Ahead: $ahead',
                                          style: const TextStyle(color: Colors.black87),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  ElevatedButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => QueueConfirmationScreen(courtId: c),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                    child: const Text('View'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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
