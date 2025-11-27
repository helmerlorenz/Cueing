import 'package:flutter/material.dart';
import '../services/queue_service.dart';
import 'admin_billing_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _queueService = QueueService();
  final List<String> courts = List.generate(6, (i) => 'Court ${i + 1}');
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(_selectedTab == 0 ? 'Queue Management' : 'Billing Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 0
                                ? const Color(0xFF10B981)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.queue,
                            color: _selectedTab == 0
                                ? const Color(0xFF10B981)
                                : Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Queues',
                            style: TextStyle(
                              color: _selectedTab == 0
                                  ? const Color(0xFF10B981)
                                  : Colors.white70,
                              fontWeight: _selectedTab == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 1
                                ? const Color(0xFF10B981)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: _selectedTab == 1
                                ? const Color(0xFF10B981)
                                : Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Billing',
                            style: TextStyle(
                              color: _selectedTab == 1
                                  ? const Color(0xFF10B981)
                                  : Colors.white70,
                              fontWeight: _selectedTab == 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _selectedTab == 0 ? _buildQueueTab() : const AdminBillingScreen(),
    );
  }

  Widget _buildQueueTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'QUEUE MANAGEMENT',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage Court Queues',
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
                  return FutureBuilder<int>(
                    future: _queueService.queueLength(c),
                    builder: (context, snapshot) {
                      final len = snapshot.data ?? 0;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2D2D2D),
                            width: 1,
                          ),
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
                                    color: Color(0xFF10B981),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$len in queue',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: len > 0
                                      ? () async {
                                          await _queueService.popNext(c);
                                          setState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Started next player on $c'),
                                              backgroundColor: Colors.green,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    disabledBackgroundColor: Colors.grey[800],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.play_arrow, size: 18),
                                      SizedBox(width: 6),
                                      Text('Start Next'),
                                    ],
                                  ),
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
    );
  }
}
