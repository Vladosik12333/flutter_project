// lib/widgets/charts/expense_bar_chart.dart
import 'package:flutter/material.dart';
import '../../db/app_database.dart';

class ExpenseBarChart extends StatelessWidget {
  final List<Transaction> transactions;

  const ExpenseBarChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Group expenses by category
    final Map<String, double> data = {};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      data[t.category] = (data[t.category] ?? 0) + t.amount;
    }

    if (data.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text('No expenses yet to display chart.'),
      );
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 150,
      child: ListView(
        children: data.entries.map((entry) {
          final label = entry.key;
          final value = entry.value;
          final fraction = maxValue == 0 ? 0.0 : value / maxValue;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    value.toStringAsFixed(0),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
