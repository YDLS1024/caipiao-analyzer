import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/history_screen.dart';
import 'screens/input_screen.dart';
import 'screens/result_screen.dart';
import 'screens/rules_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final state = AppState();
  await state.load();

  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const CaipiaoApp(),
    ),
  );
}

class CaipiaoApp extends StatelessWidget {
  const CaipiaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '大乐透规则分析',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final Widget page;
    switch (_index) {
      case 1:
        page = const RulesScreen();
      case 2:
        page = const ResultScreen();
      case 3:
        page = const HistoryScreen();
      default:
        page = const InputScreen();
    }

    return Scaffold(
      body: page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.paper,
        indicatorColor: AppColors.mint.withValues(alpha: 0.25),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_3x3_outlined),
            selectedIcon: Icon(Icons.grid_3x3),
            label: '输入',
          ),
          NavigationDestination(
            icon: Icon(Icons.rule_outlined),
            selectedIcon: Icon(Icons.rule),
            label: '规则',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: '分析',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '历史',
          ),
        ],
      ),
    );
  }
}
