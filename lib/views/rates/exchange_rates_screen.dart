import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';

class ExchangeRatesScreen extends StatefulWidget {
  const ExchangeRatesScreen({super.key});

  @override
  State<ExchangeRatesScreen> createState() => _ExchangeRatesScreenState();
}

class _ExchangeRatesScreenState extends State<ExchangeRatesScreen> {
  final _baseController = TextEditingController(text: 'EUR');

  @override
  void initState() {
    super.initState();
    // Load default rates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadExchangeRates(base: 'EUR');
    });
  }

  @override
  void dispose() {
    _baseController.dispose();
    super.dispose();
  }

  void _load() {
    final base = _baseController.text.trim().toUpperCase();
    if (base.isEmpty) return;
    context.read<TransactionProvider>().loadExchangeRates(base: base);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Exchange Rates')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _baseController,
                    decoration: const InputDecoration(
                      labelText: 'Base',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: provider.ratesLoading ? null : _load,
                  icon: const Icon(Icons.download),
                  label: const Text('Load'),
                ),
                const SizedBox(width: 12),
                if (provider.exchangeRates != null)
                  Text('Date: ${provider.exchangeRates!.date}'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _RatesBody(provider: provider)),
          ],
        ),
      ),
    );
  }
}

class _RatesBody extends StatelessWidget {
  final TransactionProvider provider;

  const _RatesBody({required this.provider});

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
      return const Center(child: Text('No rates loaded.'));
    }

    final entries = rates.rates.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final e = entries[i];
        return ListTile(
          title: Text(e.key),
          trailing: Text(e.value.toStringAsFixed(4)),
        );
      },
    );
  }
}
