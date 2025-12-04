import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../views/home/home_screen.dart';
import '../views/transaction_edit/add_edit_transaction_screen.dart';
import '../views/transaction_detail/transaction_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
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
  ],
);
