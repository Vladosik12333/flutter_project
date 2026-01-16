import '../../db/app_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../views/home/home_screen.dart';
import '../views/transaction_edit/add_edit_transaction_screen.dart';
import '../views/transaction_detail/transaction_detail_screen.dart';
import '../views/rates/exchange_rates_screen.dart';
import '../views/transactions/all_transactions_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ----------------
    // HOME
    // ----------------
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),

    // ----------------
    // EXCHANGE RATES
    // ----------------
    GoRoute(
      path: '/rates',
      name: 'rates',
      builder: (context, state) => const ExchangeRatesScreen(),
    ),

    // ----------------
    // TRANSACTIONS
    // ----------------
    GoRoute(
      path: '/transactions',
      name: 'transactionsAll',
      builder: (context, state) => const AllTransactionsScreen(),
    ),

    GoRoute(
      path: '/transaction/new',
      name: 'transactionNew',
      builder: (context, state) => const AddEditTransactionScreen(),
    ),

    GoRoute(
      path: '/transaction/:id',
      name: 'transactionDetail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return TransactionDetailScreen(id: id);
      },
    ),

    GoRoute(
      path: '/transaction/:id/edit',
      name: 'transactionEdit',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AddEditTransactionScreen(editId: id);
      },
    ),
  ],
);
