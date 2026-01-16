import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';
import '../../widgets/common/app_card.dart';

class TransactionDetailScreen extends StatelessWidget {
  final int id;
  const TransactionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.pushNamed(
              'transactionEdit',
              pathParameters: {'id': id.toString()},
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await context.read<TransactionProvider>().deleteById(id);
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder(
          // ✅ Requirement: reactive UI update via StreamBuilder
          stream: p.watchTransactionById(id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final t = snapshot.data!;
            final isIncome = t.type == 'income';
            final converted = p.convertToBase(t.amount, t.currency);

            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),

                  _RowLine(label: 'Type', value: t.type),
                  _RowLine(label: 'Category', value: t.category),
                  _RowLine(
                    label: 'Date',
                    value: t.date.toLocal().toString().split('.').first,
                  ),

                  const Divider(height: 28),

                  Text(
                    'Amount (Base: ${p.baseCurrency})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    '${isIncome ? '+' : '-'} ${converted.toStringAsFixed(2)} ${p.baseCurrency}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Original: ${t.amount.toStringAsFixed(2)} ${t.currency}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RowLine extends StatelessWidget {
  final String label;
  final String value;

  const _RowLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
