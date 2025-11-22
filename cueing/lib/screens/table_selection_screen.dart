import 'package:flutter/material.dart';
import 'game_confirmation_screen.dart';

class TableSelectionScreen extends StatefulWidget {
  const TableSelectionScreen({super.key});

  @override
  State<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  String? selectedTable;

  Widget _buildTableButton(String tableNumber) {
    final isSelected = selectedTable == tableNumber;
    return ElevatedButton(
      onPressed: () => setState(() => selectedTable = tableNumber),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF6B00FF) : Colors.white,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF6B00FF),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? Colors.white : const Color(0xFF6B00FF), width: 2),
        ),
      ),
      child: Text(tableNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('TABLE', style: TextStyle(color: Color(0xFF6B00FF), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              const Text('TABLE\nSELECTION', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: List.generate(10, (i) => _buildTableButton('TABLE ${i + 1}')),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: selectedTable != null
                    ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameConfirmationScreen(table: selectedTable!)))
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6B00FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Proceed to confirmation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}