import 'dart:math' as math;
import 'package:flutter/material.dart';

class MonthDonutChart extends StatelessWidget {
  final double income;
  final double expense;
  final String currency;

  const MonthDonutChart({
    super.key,
    required this.income,
    required this.expense,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final total = (income + expense);
    final safeTotal = total <= 0 ? 1.0 : total;

    final incomePct = (income / safeTotal).clamp(0.0, 1.0);
    final expensePct = (expense / safeTotal).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: CustomPaint(
            painter: _DonutPainter(
              incomePct: incomePct,
              expensePct: expensePct,
              trackColor: Theme.of(context).dividerColor.withOpacity(0.25),
              incomeColor: Colors.green,
              expenseColor: Colors.red,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(incomePct * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('Income', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendRow(
                color: Colors.green,
                label: 'Income',
                value: '${income.toStringAsFixed(2)} $currency',
              ),
              const SizedBox(height: 10),
              _LegendRow(
                color: Colors.red,
                label: 'Expenses',
                value: '${expense.toStringAsFixed(2)} $currency',
              ),
              const SizedBox(height: 10),
              _LegendRow(
                color: Colors.teal,
                label: 'Net',
                value: '${(income - expense).toStringAsFixed(2)} $currency',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double incomePct;
  final double expensePct;
  final Color trackColor;
  final Color incomeColor;
  final Color expenseColor;

  _DonutPainter({
    required this.incomePct,
    required this.expensePct,
    required this.trackColor,
    required this.incomeColor,
    required this.expenseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.14;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final incomePaint = Paint()
      ..color = incomeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final expensePaint = Paint()
      ..color = expenseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // Track
    canvas.drawCircle(center, radius, track);

    // Start at top
    final start = -math.pi / 2;

    // Income arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      2 * math.pi * incomePct,
      false,
      incomePaint,
    );

    // Expense arc right after income
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start + 2 * math.pi * incomePct,
      2 * math.pi * expensePct,
      false,
      expensePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.incomePct != incomePct ||
        oldDelegate.expensePct != expensePct ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.incomeColor != incomeColor ||
        oldDelegate.expenseColor != expenseColor;
  }
}
