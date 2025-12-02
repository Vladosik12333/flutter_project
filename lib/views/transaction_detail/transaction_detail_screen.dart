// lib/views/transaction_detail/transaction_detail_screen.dart
import 'package:flutter/material.dart';

class TransactionDetailScreen extends StatelessWidget {
  final int id;

  const TransactionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail'),
      ),
      body: Center(
        child: Text(
          'Details for transaction ID: $id\n'
          'You can extend this screen to show full information and delete/edit.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
