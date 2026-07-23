import 'dart:math';

import '../models/rule.dart';
import '../models/ticket.dart';

/// 单条规则的应用结果
class RuleResult {
  const RuleResult({
    required this.rule,
    required this.ticket,
    required this.warnings,
    required this.redDetail,
    required this.blueDetail,
    required this.ok,
  });

  final AnalysisRule rule;
  final Ticket? ticket;
  final List<String> warnings;
  final List<SlotDetail> redDetail;
  final List<SlotDetail> blueDetail;
  final bool ok;
}

/// 输出某一位置的解析明细
class SlotDetail {
  const SlotDetail({
    required this.outputIndex,
    required this.source,
    required this.value,
    required this.fromMissing,
    this.ruleOrderValue,
  });

  final int outputIndex;
  final SlotSource source;

  /// 最终进入结果票的号码（升序排列后的对应位可能不同，这里保留规则位取值）
  final int? value;

  final bool fromMissing;

  /// 按规则位填完后、强制升序前的该位数值
  final int? ruleOrderValue;
}

/// 规则引擎：红 / 蓝各自独立，数字不跨越
///
/// 规则语义：
/// - `①1`：输出该位 = 第 1 注的第 1 个号码（原样取值，不重排引用）
/// - `空`：随机取一个不在当前 5 注同色号码中的数，并尽量符合升序
/// - 最终号码始终按升序排列；若规则取值本身无法升序，仍排列并给出提示
class RuleEngine {
  RuleEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<RuleResult> applyAll({
    required List<Ticket> tickets,
    required List<AnalysisRule> rules,
  }) {
    return rules
        .where((r) => r.enabled)
        .map((r) => apply(tickets: tickets, rule: r))
        .toList();
  }

  RuleResult apply({
    required List<Ticket> tickets,
    required AnalysisRule rule,
  }) {
    final warnings = <String>[];

    if (tickets.length != Ticket.inputTicketCount) {
      warnings.add('需要恰好输入 ${Ticket.inputTicketCount} 注号码');
      return RuleResult(
        rule: rule,
        ticket: null,
        warnings: warnings,
        redDetail: const [],
        blueDetail: const [],
        ok: false,
      );
    }

    for (var i = 0; i < tickets.length; i++) {
      if (!tickets[i].isComplete) {
        warnings.add('第 ${i + 1} 注号码不完整或非法');
      }
    }
    if (warnings.isNotEmpty) {
      return RuleResult(
        rule: rule,
        ticket: null,
        warnings: warnings,
        redDetail: const [],
        blueDetail: const [],
        ok: false,
      );
    }

    final allReds = <int>{};
    final allBlues = <int>{};
    for (final t in tickets) {
      allReds.addAll(t.reds);
      allBlues.addAll(t.blues);
    }

    final missingReds = [
      for (var n = Ticket.redMin; n <= Ticket.redMax; n++)
        if (!allReds.contains(n)) n,
    ];
    final missingBlues = [
      for (var n = Ticket.blueMin; n <= Ticket.blueMax; n++)
        if (!allBlues.contains(n)) n,
    ];

    final redResolved = _resolveColor(
      tickets: tickets,
      slots: rule.redSlots,
      expectedCount: Ticket.redCount,
      readBall: (t, pos) => t.reds[pos],
      missingPool: missingReds,
      colorName: '红球',
      maxPos: Ticket.redCount,
      warnings: warnings,
    );

    final blueResolved = _resolveColor(
      tickets: tickets,
      slots: rule.blueSlots,
      expectedCount: Ticket.blueCount,
      readBall: (t, pos) => t.blues[pos],
      missingPool: missingBlues,
      colorName: '蓝球',
      maxPos: Ticket.blueCount,
      warnings: warnings,
    );

    if (redResolved.values.any((v) => v == null) ||
        blueResolved.values.any((v) => v == null)) {
      return RuleResult(
        rule: rule,
        ticket: null,
        warnings: warnings,
        redDetail: redResolved.details,
        blueDetail: blueResolved.details,
        ok: false,
      );
    }

    final redRuleOrder = redResolved.values.cast<int>().toList();
    final blueRuleOrder = blueResolved.values.cast<int>().toList();

    _checkOrderAndDupes(
      colorName: '红球',
      ruleOrder: redRuleOrder,
      warnings: warnings,
    );
    _checkOrderAndDupes(
      colorName: '蓝球',
      ruleOrder: blueRuleOrder,
      warnings: warnings,
    );

    // 无论规则序是否合法，最终都升序排列
    final reds = [...redRuleOrder]..sort();
    final blues = [...blueRuleOrder]..sort();

    final ok = warnings.isEmpty;
    return RuleResult(
      rule: rule,
      ticket: Ticket(reds: reds, blues: blues),
      warnings: warnings,
      redDetail: redResolved.details,
      blueDetail: blueResolved.details,
      ok: ok,
    );
  }

  void _checkOrderAndDupes({
    required String colorName,
    required List<int> ruleOrder,
    required List<String> warnings,
  }) {
    if (ruleOrder.toSet().length != ruleOrder.length) {
      warnings.add(
        '$colorName 按规则取值有重复：${_fmtList(ruleOrder)}，请检查规则引用',
      );
    }

    var ascending = true;
    for (var i = 1; i < ruleOrder.length; i++) {
      if (ruleOrder[i] <= ruleOrder[i - 1]) {
        ascending = false;
        break;
      }
    }
    if (!ascending) {
      final sorted = [...ruleOrder]..sort();
      warnings.add(
        '$colorName 按规则取值无法保持升序（规则序：${_fmtList(ruleOrder)}），'
        '已强制升序排列为 ${_fmtList(sorted)}',
      );
    }
  }

  _ColorResolve _resolveColor({
    required List<Ticket> tickets,
    required List<SlotSource> slots,
    required int expectedCount,
    required int Function(Ticket t, int pos) readBall,
    required List<int> missingPool,
    required String colorName,
    required int maxPos,
    required List<String> warnings,
  }) {
    if (slots.length != expectedCount) {
      warnings.add('$colorName 规则位数应为 $expectedCount');
      return _ColorResolve(
        values: List<int?>.filled(expectedCount, null),
        details: const [],
      );
    }

    final values = List<int?>.filled(expectedCount, null);
    final fromMissing = List<bool>.filled(expectedCount, false);
    final used = <int>{};

    // 1) 引用位原样取值（①1 = 第1注第1个）
    for (var i = 0; i < slots.length; i++) {
      final src = slots[i];
      if (src.isEmpty) continue;
      final ti = src.ticketIndex!;
      final pos = src.position!;
      if (ti < 0 || ti >= tickets.length || pos < 0 || pos >= maxPos) {
        warnings.add('$colorName 第 ${i + 1} 位引用 ${src.label} 越界');
        continue;
      }
      final v = readBall(tickets[ti], pos);
      values[i] = v;
      used.add(v);
    }

    // 2) 空位：随机取「不在当前 5 注中」且尽量符合升序的号码
    for (var i = 0; i < slots.length; i++) {
      if (!slots[i].isEmpty) continue;

      final lower = _nearestLeft(values, i);
      final upper = _nearestRight(values, i);

      final fitting = missingPool
          .where((n) => !used.contains(n))
          .where((n) => lower == null || n > lower)
          .where((n) => upper == null || n < upper)
          .toList();

      List<int> candidates = fitting;
      if (candidates.isEmpty) {
        candidates =
            missingPool.where((n) => !used.contains(n)).toList();
        if (candidates.isNotEmpty) {
          warnings.add(
            '$colorName 第 ${i + 1} 位空位无法找到符合升序的未出现号码'
            '（需 > ${lower ?? '无'} 且 < ${upper ?? '无'}），已随机取未出现号码',
          );
        }
      }

      if (candidates.isEmpty) {
        warnings.add('$colorName 第 ${i + 1} 位空位无可用的未出现号码');
        continue;
      }

      final picked = candidates[_random.nextInt(candidates.length)];
      values[i] = picked;
      used.add(picked);
      fromMissing[i] = true;
    }

    final details = <SlotDetail>[
      for (var i = 0; i < slots.length; i++)
        SlotDetail(
          outputIndex: i,
          source: slots[i],
          value: values[i],
          fromMissing: fromMissing[i],
          ruleOrderValue: values[i],
        ),
    ];

    return _ColorResolve(values: values, details: details);
  }

  int? _nearestLeft(List<int?> values, int index) {
    for (var i = index - 1; i >= 0; i--) {
      if (values[i] != null) return values[i];
    }
    return null;
  }

  int? _nearestRight(List<int?> values, int index) {
    for (var i = index + 1; i < values.length; i++) {
      if (values[i] != null) return values[i];
    }
    return null;
  }

  static String _fmtList(List<int> list) =>
      list.map((n) => n.toString().padLeft(2, '0')).join(' ');
}

class _ColorResolve {
  const _ColorResolve({required this.values, required this.details});
  final List<int?> values;
  final List<SlotDetail> details;
}
