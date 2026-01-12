import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/charts/expense_bar_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // Load exchange data once (after first build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadExchangeRates(base: 'EUR');
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    // Transactions list filtered (Today/Week/Month/All)
    final txs = txProvider.filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Finance Tracker'),
        actions: [
          IconButton(
            tooltip: 'Refresh FX',
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<TransactionProvider>()
                .loadExchangeRates(base: 'EUR'),
          ),
          IconButton(
            tooltip: themeProvider.isDark ? 'Light mode' : 'Dark mode',
            icon: Icon(
              themeProvider.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
          IconButton(
            tooltip: 'Exchange Rates Screen',
            icon: const Icon(Icons.currency_exchange),
            onPressed: () => context.pushNamed('rates'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add transaction',
        onPressed: () => context.pushNamed('transactionNew'),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 1100;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // =========================
                  // DASHBOARD GRID (3 CARDS)
                  // =========================
                  // TOP DASHBOARD
                  LayoutBuilder(
                    builder: (context, c) {
                      final isWide = c.maxWidth >= 1100;

                      if (isWide) {
                        return DashboardTopRow(
                          income: txProvider.totalIncome,
                          expense: txProvider.totalExpense,
                          balance: txProvider.balance,
                        );
                      }

                      // Narrow layout (stack)
                      return Column(
                        children: [
                          _KpiCard(
                            title: 'Income',
                            value: txProvider.totalIncome,
                            icon: Icons.trending_up,
                            accent: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _KpiCard(
                            title: 'Expenses',
                            value: txProvider.totalExpense,
                            icon: Icons.trending_down,
                            accent: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          _KpiCard(
                            title: 'Balance',
                            value: txProvider.balance,
                            icon: Icons.account_balance_wallet_outlined,
                            accent: Colors.teal,
                          ),
                          const SizedBox(height: 16),
                          const _MiniChartCard(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 16),

                  // =========================
                  // CHART CARD
                  // =========================
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Spending by Category',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ExpenseBarChart(transactions: txProvider.transactions),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // LIVE EXCHANGE DATA (NOT "TIPS")
                  // =========================
                  SizedBox(
                    height: 320,
                    child: AppCard(
                      child: _MarketSnapshot(provider: txProvider),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // TRANSACTIONS HEADER + FILTER
                  // =========================
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Transactions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      _FilterChips(
                        current: txProvider.filter,
                        onChanged: (f) =>
                            context.read<TransactionProvider>().setFilter(f),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // =========================
                  // TRANSACTIONS LIST
                  // =========================
                  if (txProvider.state == TransactionViewState.loading)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (txs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text('No transactions yet. Tap + to add one.'),
                      ),
                    )
                  else
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: txs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final t = txs[index];
                          final isIncome = t.type == 'income';

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
                            trailing: Text(
                              '${isIncome ? '+' : '-'} ${t.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _summaryCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
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
          ),
        ],
      ),
    );
  }

  static String _dateShort(DateTime d) {
    final s = d.toLocal().toString();
    return s.split(' ').first;
  }
}

// =========================
// MARKET SNAPSHOT WIDGET
// =========================
class _MarketSnapshot extends StatelessWidget {
  final TransactionProvider provider;
  const _MarketSnapshot({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.ratesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.ratesError != null) {
      return Center(
        child: Text(
          provider.ratesError!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    final rates = provider.exchangeRates;
    if (rates == null) {
      return const Center(child: Text('No market data loaded yet.'));
    }

    final wanted = ['USD', 'PLN', 'GBP', 'CHF', 'JPY', 'TRY'];
    final items = wanted
        .where((c) => rates.rates.containsKey(c))
        .map((c) => MapEntry(c, rates.rates[c]!))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Live Exchange Data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              'Date: ${rates.date}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child: GridView.builder(
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final e = items[index];
              return AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.currency_exchange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '1 ${rates.base} = ${e.value.toStringAsFixed(4)} ${e.key}',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =========================
// FILTER CHIPS
// =========================
class _FilterChips extends StatelessWidget {
  final TxFilter current;
  final ValueChanged<TxFilter> onChanged;

  const _FilterChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: current == TxFilter.all,
          onSelected: (_) => onChanged(TxFilter.all),
        ),
        ChoiceChip(
          label: const Text('Today'),
          selected: current == TxFilter.today,
          onSelected: (_) => onChanged(TxFilter.today),
        ),
        ChoiceChip(
          label: const Text('This Week'),
          selected: current == TxFilter.week,
          onSelected: (_) => onChanged(TxFilter.week),
        ),
        ChoiceChip(
          label: const Text('This Month'),
          selected: current == TxFilter.month,
          onSelected: (_) => onChanged(TxFilter.month),
        ),
      ],
    );
  }
}

class DashboardTopRow extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;

  const DashboardTopRow({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 1100;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        title: 'Income',
                        value: income,
                        icon: Icons.trending_up,
                        accent: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        title: 'Expenses',
                        value: expense,
                        icon: Icons.trending_down,
                        accent: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        title: 'Balance',
                        value: balance,
                        icon: Icons.account_balance_wallet_outlined,
                        accent: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: _MiniChartCard()),
            ],
          );
        }

        // Not wide (stack)
        return Column(
          children: const [
            // We'll pass values via constructor in usage below
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color accent;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    // Using your AppCard helper
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withOpacity(0.12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  value.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChartCard extends StatelessWidget {
  const _MiniChartCard();

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Spending Overview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ExpenseBarChart(transactions: txProvider.transactions),
        ],
      ),
    );
  }
}
