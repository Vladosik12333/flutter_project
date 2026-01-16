import '../../db/app_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';
import '../../widgets/common/app_card.dart';

enum _TypeFilter { all, income, expense }

enum _SortMode { newest, oldest, amountHigh, amountLow }

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final _searchCtrl = TextEditingController();

  _TypeFilter _typeFilter = _TypeFilter.all;
  _SortMode _sortMode = _SortMode.newest;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TransactionProvider>();

    final query = _searchCtrl.text.trim().toLowerCase();

    // 1) start from all tx
    List<Transaction> list = List<Transaction>.from(p.transactions);

    // 2) type filter
    if (_typeFilter == _TypeFilter.income) {
      list = list.where((t) => t.type == 'income').toList();
    } else if (_typeFilter == _TypeFilter.expense) {
      list = list.where((t) => t.type == 'expense').toList();
    }

    // 3) search filter (title + category)
    if (query.isNotEmpty) {
      list = list.where((t) {
        final title = t.title.toLowerCase();
        final cat = t.category.toLowerCase();
        return title.contains(query) || cat.contains(query);
      }).toList();
    }

    // 4) sort
    list.sort((a, b) {
      switch (_sortMode) {
        case _SortMode.newest:
          return b.date.compareTo(a.date);
        case _SortMode.oldest:
          return a.date.compareTo(b.date);
        case _SortMode.amountHigh:
          final av = p.convertToBase(a.amount, a.currency);
          final bv = p.convertToBase(b.amount, b.currency);
          return bv.compareTo(av);
        case _SortMode.amountLow:
          final av = p.convertToBase(a.amount, a.currency);
          final bv = p.convertToBase(b.amount, b.currency);
          return av.compareTo(bv);
      }
    });

    // 5) summary
    double income = 0, expense = 0;
    for (final t in list) {
      final v = p.convertToBase(t.amount, t.currency);
      if (t.type == 'income') income += v;
      if (t.type == 'expense') expense += v;
    }
    final balance = income - expense;

    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // =========================
            // TOP CONTROLS (SEARCH + FILTERS)
            // =========================
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search by title or category…',
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Type chips
                      _chip(
                        label: 'All',
                        selected: _typeFilter == _TypeFilter.all,
                        onTap: () =>
                            setState(() => _typeFilter = _TypeFilter.all),
                      ),
                      _chip(
                        label: 'Income',
                        selected: _typeFilter == _TypeFilter.income,
                        onTap: () =>
                            setState(() => _typeFilter = _TypeFilter.income),
                      ),
                      _chip(
                        label: 'Expense',
                        selected: _typeFilter == _TypeFilter.expense,
                        onTap: () =>
                            setState(() => _typeFilter = _TypeFilter.expense),
                      ),

                      const SizedBox(width: 12),

                      // Sort dropdown
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort, size: 18),
                          const SizedBox(width: 8),
                          DropdownButton<_SortMode>(
                            value: _sortMode,
                            items: const [
                              DropdownMenuItem(
                                value: _SortMode.newest,
                                child: Text('Newest'),
                              ),
                              DropdownMenuItem(
                                value: _SortMode.oldest,
                                child: Text('Oldest'),
                              ),
                              DropdownMenuItem(
                                value: _SortMode.amountHigh,
                                child: Text('Amount ↓'),
                              ),
                              DropdownMenuItem(
                                value: _SortMode.amountLow,
                                child: Text('Amount ↑'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _sortMode = v);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Summary row
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _pill(
                        context,
                        label: 'Count',
                        value: '${list.length}',
                        icon: Icons.receipt_long,
                      ),
                      _pill(
                        context,
                        label: 'Income',
                        value: '${income.toStringAsFixed(2)} ${p.baseCurrency}',
                        icon: Icons.trending_up,
                      ),
                      _pill(
                        context,
                        label: 'Expense',
                        value:
                            '${expense.toStringAsFixed(2)} ${p.baseCurrency}',
                        icon: Icons.trending_down,
                      ),
                      _pill(
                        context,
                        label: 'Balance',
                        value:
                            '${balance.toStringAsFixed(2)} ${p.baseCurrency}',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // =========================
            // LIST
            // =========================
            Expanded(
              child: list.isEmpty
                  ? const Center(
                      child: Text('No transactions match your filters.'),
                    )
                  : AppCard(
                      padding: EdgeInsets.zero,
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final t = list[index];
                          final isIncome = t.type == 'income';
                          final converted = p.convertToBase(
                            t.amount,
                            t.currency,
                          );

                          return ListTile(
                            onTap: () => context.pushNamed(
                              'transactionDetail',
                              pathParameters: {'id': t.id.toString()},
                            ),
                            leading: Icon(
                              isIncome
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                            title: Text(t.title),
                            subtitle: Text(
                              '${t.category} • ${_dateShort(t.date)}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'} ${converted.toStringAsFixed(2)} ${p.baseCurrency}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isIncome ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '(${t.amount.toStringAsFixed(2)} ${t.currency})',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _dateShort(DateTime d) =>
      d.toLocal().toString().split(' ').first;

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _pill(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
