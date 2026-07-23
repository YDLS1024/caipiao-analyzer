import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:caipiao_analyzer/models/rule.dart';
import 'package:caipiao_analyzer/models/ticket.dart';
import 'package:caipiao_analyzer/services/rule_engine.dart';

void main() {
  final tickets = [
    const Ticket(reds: [1, 5, 12, 20, 33], blues: [2, 8]),
    const Ticket(reds: [3, 7, 15, 22, 30], blues: [1, 9]),
    const Ticket(reds: [4, 9, 18, 25, 31], blues: [3, 7]),
    const Ticket(reds: [2, 11, 19, 28, 34], blues: [4, 10]),
    const Ticket(reds: [6, 14, 21, 27, 35], blues: [5, 11]),
  ];

  test('①1 原样取值；空位随机取未出现且尽量升序；最终升序', () {
    final engine = RuleEngine(random: Random(1));
    final rule = AnalysisRule(
      id: 't1',
      name: 'test',
      redSlots: const [
        SlotSource.ref(0, 0), // ①1 = 1
        SlotSource.ref(1, 1), // ②2 = 7
        SlotSource.ref(2, 2), // ③3 = 18
        SlotSource.ref(3, 3), // ④4 = 28
        SlotSource.empty(),
      ],
      blueSlots: const [
        SlotSource.ref(0, 0), // ①1 = 2
        SlotSource.ref(1, 1), // ②2 = 9
      ],
    );

    final result = engine.apply(tickets: tickets, rule: rule);
    expect(result.ticket, isNotNull);

    // 引用位保持原值：1,7,18,28，空位 >28 且未出现
    expect(result.redDetail[0].value, 1);
    expect(result.redDetail[1].value, 7);
    expect(result.redDetail[2].value, 18);
    expect(result.redDetail[3].value, 28);
    expect(result.redDetail[4].fromMissing, isTrue);
    expect(result.redDetail[4].value! > 28, isTrue);

    final allReds = tickets.expand((t) => t.reds).toSet();
    expect(allReds.contains(result.redDetail[4].value), isFalse);

    // 最终升序
    final reds = result.ticket!.reds;
    expect(reds, [...reds]..sort());
    expect(result.ticket!.blues, [2, 9]);
    expect(result.ok, isTrue);
  });

  test('规则取值无法升序时仍排列并提示', () {
    final engine = RuleEngine(random: Random(0));
    final rule = AnalysisRule(
      id: 't2',
      name: 'disorder',
      redSlots: const [
        SlotSource.ref(0, 4), // ①5 = 33
        SlotSource.ref(0, 0), // ①1 = 1
        SlotSource.ref(0, 1), // ①2 = 5
        SlotSource.ref(0, 2), // ①3 = 12
        SlotSource.ref(0, 3), // ①4 = 20
      ],
      blueSlots: const [
        SlotSource.ref(0, 1), // ①2 = 8
        SlotSource.ref(0, 0), // ①1 = 2
      ],
    );

    final result = engine.apply(tickets: tickets, rule: rule);
    expect(result.ticket, isNotNull);
    expect(result.ok, isFalse);
    expect(result.warnings.any((w) => w.contains('无法保持升序')), isTrue);
    // 仍强制升序输出
    expect(result.ticket!.reds, [1, 5, 12, 20, 33]);
    expect(result.ticket!.blues, [2, 8]);
  });

  test('标签 ①1', () {
    expect(const SlotSource.ref(0, 0).label, '①1');
    expect(const SlotSource.ref(1, 2).label, '②3');
    expect(const SlotSource.empty().label, '空');
  });
}
