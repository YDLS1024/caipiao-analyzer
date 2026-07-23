import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:caipiao_analyzer/main.dart';
import 'package:caipiao_analyzer/state/app_state.dart';

void main() {
  testWidgets('应用启动显示输入页', (tester) async {
    final state = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const CaipiaoApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('输入'), findsWidgets);
  });
}
