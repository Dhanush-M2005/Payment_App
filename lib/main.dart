import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/amount_screen.dart';
import 'screens/risk_screen.dart';
import 'screens/warning_screen.dart';
import 'screens/redirect_screen.dart';
import 'package:provider/provider.dart';
import 'package:upi_shield/database/app_database.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/pay_anyone_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await $FloorAppDatabase
      .databaseBuilder('safeupi_v2.db')
      .build();

  runApp(
    Provider<AppDatabase>.value(value: database, child: const UpiShieldApp()),
  );
}

class UpiShieldApp extends StatelessWidget {
  const UpiShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPI Shield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const PasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/amount': (context) => const AmountScreen(),
        '/risk': (context) => const RiskScreen(),
        '/warning': (context) => const WarningScreen(),
        '/redirect': (context) => const RedirectScreen(),
        '/transactions': (context) => const TransactionHistoryScreen(),
        '/pay_anyone': (context) => const PayAnyoneScreen(),
      },
    );
  }
}
