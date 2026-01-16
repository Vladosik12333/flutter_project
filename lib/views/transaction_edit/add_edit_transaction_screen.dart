import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di.dart';
import '../../db/app_database.dart';
import '../../providers/transaction_provider.dart';
import '../../repositories/finance_repository.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final int? editId;
  const AddEditTransactionScreen({super.key, this.editId});

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isIncome = false;
  String _category = 'Other';

  // ✅ NEW: currency for this transaction
  String _currency = 'EUR';

  bool _loading = false;
  bool _prefilling = false;

  final List<String> _categories = const [
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Salary',
    'Other',
  ];

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _prefill();
  }

  Future<void> _prefill() async {
    setState(() => _prefilling = true);
    try {
      final repo = getIt<FinanceRepository>();
      final Transaction tx = await repo
          .watchTransactionById(widget.editId!)
          .first;

      if (!mounted) return;

      _titleController.text = tx.title;
      _amountController.text = tx.amount.toStringAsFixed(2);
      _isIncome = tx.type == 'income';
      _category = _categories.contains(tx.category) ? tx.category : 'Other';
      _currency = tx.currency;

      setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load transaction for editing.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _prefilling = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double _parseAmount(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    return double.parse(normalized);
  }

  Future<void> _save() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final title = _titleController.text.trim();
    final amount = _parseAmount(_amountController.text);

    final txProvider = context.read<TransactionProvider>();

    try {
      if (_isEdit) {
        await txProvider.editTransaction(
          id: widget.editId!,
          title: title,
          amount: amount,
          isIncome: _isIncome,
          category: _category,
          currency: _currency,
          date: DateTime.now(),
        );
      } else {
        await txProvider.addTransaction(
          title: title,
          amount: amount,
          isIncome: _isIncome,
          category: _category,
          currency: _currency,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final title = _isEdit ? 'Edit Transaction' : 'Add Transaction';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _prefilling
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        final normalized = value.trim().replaceAll(',', '.');
                        final parsed = double.tryParse(normalized);
                        if (parsed == null || parsed <= 0) {
                          return 'Amount must be a positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ✅ NEW: Currency dropdown
                    DropdownButtonFormField<String>(
                      value: _currency,
                      items: txProvider.supportedCurrencies
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _currency = value);
                      },
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Type: '),
                        const SizedBox(width: 8),
                        DropdownButton<bool>(
                          value: _isIncome,
                          items: const [
                            DropdownMenuItem(
                              value: false,
                              child: Text('Expense'),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text('Income'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _isIncome = value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _category,
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _category = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _save,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isEdit ? 'Update' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
