import 'package:flutter/material.dart';
import 'queue_confirmation_screen.dart';

class CourtSelectionScreen extends StatefulWidget {
  const CourtSelectionScreen({super.key});

  @override
  State<CourtSelectionScreen> createState() => _CourtSelectionScreenState();
}

class _CourtSelectionScreenState extends State<CourtSelectionScreen> {
  String? selectedCourt;

  Widget _buildCourtButton(String courtName) {
    final isSelected = selectedCourt == courtName;
    return ElevatedButton(
      onPressed: () => setState(() => selectedCourt = courtName),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF10B981) : Colors.white,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF10B981),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(courtName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
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
              const Text('COURTS', style: TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Court Selection', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: List.generate(6, (i) => _buildCourtButton('Court ${i + 1}')),
                ),
              ),
              ElevatedButton(
                onPressed: selectedCourt != null
                    ? () async {
                        // Ask the user for desired play time before joining the queue
                        final minutes = await showDialog<int>(
                          context: context,
                          builder: (context) {
                            int selected = 30; // default 30 minutes
                            const int step = 30;
                            const int minMinutes = 30;
                            return AlertDialog(
                              title: const Text('Select play time'),
                              content: StatefulBuilder(
                                builder: (context, setState) {
                                  int increments = selected ~/ step;
                                  int price = increments * 50;
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            onPressed: selected > minMinutes ? () => setState(() => selected -= step) : null,
                                            icon: const Icon(Icons.remove_circle_outline),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('$selected min', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () => setState(() => selected += step),
                                            icon: const Icon(Icons.add_circle_outline),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            children: [
                                              const Text('Total', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                              const SizedBox(height: 4),
                                              Text('₱$price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Minimum 30 minutes, increments of 30 minutes. ₱50 per 30-min increment.', style: TextStyle(fontSize: 12)),
                                    ],
                                  );
                                },
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.of(context).pop(selected), child: const Text('Confirm')),
                              ],
                            );
                          },
                        );

                        if (minutes != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => QueueConfirmationScreen(courtId: selectedCourt!, durationMinutes: minutes)));
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Join Queue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
