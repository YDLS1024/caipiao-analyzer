import 'package:flutter/material.dart';

import '../models/rule.dart';
import '../models/ticket.dart';
import '../theme/app_theme.dart';
import 'ball_chip.dart';

/// 编辑一条规则的红/蓝槽位来源
class RuleEditor extends StatefulWidget {
  const RuleEditor({
    super.key,
    required this.rule,
    required this.tickets,
    required this.onChanged,
  });

  final AnalysisRule rule;
  final List<Ticket> tickets;
  final ValueChanged<AnalysisRule> onChanged;

  @override
  State<RuleEditor> createState() => _RuleEditorState();
}

class _RuleEditorState extends State<RuleEditor> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.rule.name);
  }

  @override
  void didUpdateWidget(covariant RuleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rule.id != widget.rule.id &&
        _nameCtrl.text != widget.rule.name) {
      _nameCtrl.text = widget.rule.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  AnalysisRule get rule => widget.rule;
  List<Ticket> get tickets => widget.tickets;

  Future<void> _pickSlot({
    required bool isRed,
    required int slotIndex,
  }) async {
    final maxPos = isRed ? Ticket.redCount : Ticket.blueCount;
    final current = isRed ? rule.redSlots[slotIndex] : rule.blueSlots[slotIndex];

    final picked = await showDialog<SlotSource>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.paper,
          title: Text(
            isRed ? '红球第 ${slotIndex + 1} 位来源' : '蓝球第 ${slotIndex + 1} 位来源',
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRed
                        ? '例：①1 = 第1注第1个红球；空 = 随机未出现号码'
                        : '例：①1 = 第1注第1个蓝球；空 = 随机未出现号码',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.emptySlot.withValues(alpha: 0.4),
                      ),
                    ),
                    leading: const BallChip(
                      number: null,
                      kind: BallKind.empty,
                      size: 36,
                    ),
                    title: const Text('设为空位'),
                    subtitle: const Text('随机取未出现号码，尽量符合升序'),
                    selected: current.isEmpty,
                    onTap: () =>
                        Navigator.pop(ctx, const SlotSource.empty()),
                  ),
                  const SizedBox(height: 12),
                  for (var ti = 0; ti < Ticket.inputTicketCount; ti++) ...[
                    Text(
                      '第 ${ti + 1} 注（${SlotSource.circled[ti]}）',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(maxPos, (pos) {
                        final ticket = tickets[ti];
                        final balls = isRed ? ticket.reds : ticket.blues;
                        final hasNum = pos < balls.length;
                        final selected = current.isRef &&
                            current.ticketIndex == ti &&
                            current.position == pos;
                        final label = '${SlotSource.circled[ti]}${pos + 1}';
                        // 规则选的是「位置引用」，即使尚未输入号码也可点选
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(
                              ctx,
                              SlotSource.ref(ti, pos),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                children: [
                                  BallChip(
                                    number: hasNum ? balls[pos] : null,
                                    kind: isRed ? BallKind.red : BallKind.blue,
                                    size: 44,
                                    selected: selected,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: selected
                                          ? AppColors.deepGreen
                                          : AppColors.muted,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );

    if (!mounted || picked == null) return;

    final next = rule.copy();
    if (isRed) {
      next.redSlots[slotIndex] = picked;
    } else {
      next.blueSlots[slotIndex] = picked;
    }
    widget.onChanged(next);
  }

  Widget _slotButton({
    required bool isRed,
    required int index,
    required SlotSource source,
  }) {
    final maxPos = isRed ? Ticket.redCount : Ticket.blueCount;
    int? preview;
    if (source.isRef) {
      final t = tickets[source.ticketIndex!];
      final balls = isRed ? t.reds : t.blues;
      final pos = source.position!;
      if (pos < balls.length && pos < maxPos) preview = balls[pos];
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _pickSlot(isRed: isRed, slotIndex: index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: source.isEmpty
                    ? AppColors.emptySlot.withValues(alpha: 0.5)
                    : (isRed ? AppColors.redBall : AppColors.blueBall)
                        .withValues(alpha: 0.35),
              ),
              color: AppColors.cream,
            ),
            child: Column(
              children: [
                Text(
                  '位${index + 1}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                BallChip(
                  number: source.isEmpty ? null : preview,
                  kind: source.isEmpty
                      ? BallKind.empty
                      : (isRed ? BallKind.red : BallKind.blue),
                  size: 34,
                ),
                const SizedBox(height: 4),
                Text(
                  source.label,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameCtrl,
          onChanged: (v) {
            widget.onChanged(rule.copy(name: v));
          },
          decoration: const InputDecoration(
            labelText: '规则名称',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '红球规则（不跨越蓝球）',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.redBall,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '引用位原样取值（如①1）；空位随机取未出现号码并尽量升序；最终强制升序，异常会提示',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            Ticket.redCount,
            (i) => _slotButton(
              isRed: true,
              index: i,
              source: rule.redSlots[i],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '蓝球规则（不跨越红球）',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.blueBall,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '引用位原样取值（如①1）；空位随机取未出现号码并尽量升序；最终强制升序，异常会提示',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            Ticket.blueCount,
            (i) => _slotButton(
              isRed: false,
              index: i,
              source: rule.blueSlots[i],
            ),
          ),
        ),
      ],
    );
  }
}
