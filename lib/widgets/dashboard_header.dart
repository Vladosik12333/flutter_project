import 'package:flutter/material.dart';
import '../../../widgets/common/app_card.dart';

class DashboardHeader extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;

  const DashboardHeader({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.8,
      children: [
        _card('Income', income, Colors.green),
        _card('Expenses', expense, Colors.red),
        _card('Balance', balance, Colors.teal),
      ],
    );
  }

  Widget _card(String title, double value, Color color) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
