import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/charts/expense_bar_chart.dart';
import '../../widgets/charts/month_donut_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<TransactionProvider>();
      await p.loadBaseCurrency();
      await p.loadExchangeRates(base: p.baseCurrency);
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final monthTxs = txProvider.thisMonthTransactions;
    final recentThisMonth = monthTxs.take(8).toList();

    final isLoading = txProvider.state == TransactionViewState.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Finance Tracker'),
        actions: [
          DropdownButtonHideUnderline(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String>(
                value: txProvider.baseCurrency,
                items: txProvider.supportedCurrencies
                    .map(
                      (c) =>
                          DropdownMenuItem(value: c, child: Text('Base: $c')),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  context.read<TransactionProvider>().setBaseCurrency(v);
                },
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh FX',
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<TransactionProvider>()
                .loadExchangeRates(base: txProvider.baseCurrency),
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
                  // TOP ROW (KPIs + MINI BAR)
                  // =========================
                  if (isWide)
                    DashboardTopRow(
                      income: txProvider.monthIncome,
                      expense: txProvider.monthExpense,
                      balance: txProvider.monthBalance,
                      currency: txProvider.baseCurrency,
                    )
                  else
                    Column(
                      children: [
                        _KpiCard(
                          title: 'Income (This Month)',
                          value: txProvider.monthIncome,
                          currency: txProvider.baseCurrency,
                          icon: Icons.trending_up,
                          accent: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _KpiCard(
                          title: 'Expenses (This Month)',
                          value: txProvider.monthExpense,
                          currency: txProvider.baseCurrency,
                          icon: Icons.trending_down,
                          accent: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        _KpiCard(
                          title: 'Balance (This Month)',
                          value: txProvider.monthBalance,
                          currency: txProvider.baseCurrency,
                          icon: Icons.account_balance_wallet_outlined,
                          accent: Colors.teal,
                        ),
                        const SizedBox(height: 16),
                        const _MiniChartCard(),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // =========================
                  // ✅ NEW: DONUT / CIRCLE CHART
                  // =========================
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Monthly Breakdown',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        MonthDonutChart(
                          income: txProvider.monthIncome,
                          expense: txProvider.monthExpense,
                          currency: txProvider.baseCurrency,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // SPENDING BY CATEGORY (THIS MONTH) ✅ converted in bar chart
                  // =========================
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Spending by Category (This Month)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ExpenseBarChart(transactions: monthTxs),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // LIVE EXCHANGE DATA
                  // =========================
                  SizedBox(
                    height: 240,
                    child: AppCard(
                      child: _MarketSnapshot(provider: txProvider),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // RECENT TRANSACTIONS (THIS MONTH) + VIEW ALL
                  // =========================
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent Transactions (This Month)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.pushNamed('transactionsAll'),
                        icon: const Icon(Icons.list_alt),
                        label: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (recentThisMonth.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No transactions this month yet. Tap + to add one.',
                        ),
                      ),
                    )
                  else
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentThisMonth.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final t = recentThisMonth[index];
                          final isIncome = t.type == 'income';

                          final converted = txProvider.convertToBase(
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
                                  '${isIncome ? '+' : '-'} ${converted.toStringAsFixed(2)} ${txProvider.baseCurrency}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _dateShort(DateTime d) =>
      d.toLocal().toString().split(' ').first;
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
                'Live Exchange Data (Base: ${rates.base})',
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

class DashboardTopRow extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;
  final String currency;

  const DashboardTopRow({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'Income (This Month)',
                  value: income,
                  currency: currency,
                  icon: Icons.trending_up,
                  accent: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  title: 'Expenses (This Month)',
                  value: expense,
                  currency: currency,
                  icon: Icons.trending_down,
                  accent: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  title: 'Balance (This Month)',
                  value: balance,
                  currency: currency,
                  icon: Icons.account_balance_wallet_outlined,
                  accent: Colors.teal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(flex: 5, child: _MiniChartCard()),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final double value;
  final String currency;
  final IconData icon;
  final Color accent;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.currency,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
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
                  '${value.toStringAsFixed(2)} $currency',
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
            'Spending Overview (This Month)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ExpenseBarChart(transactions: txProvider.thisMonthTransactions),
        ],
      ),
    );
  }
}
