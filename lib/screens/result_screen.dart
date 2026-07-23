import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/draw_check.dart';
import '../models/ticket.dart';
import '../services/rule_engine.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ball_chip.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final results = state.lastResults;
    final enabled = state.enabledRuleCount;

    return Scaffold(
      appBar: AppBar(title: const Text('分析结果')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.lg,
          AppSpace.lg,
          100,
        ),
        children: [
          FilledButton.icon(
            onPressed: !state.allTicketsReady || enabled == 0
                ? null
                : () {
                    final list = state.analyze();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '已按 $enabled 条规则生成 ${list.length} 注号码',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.auto_awesome),
            label: Text('开始分析（$enabled 条规则 → $enabled 注）'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            state.allTicketsReady
                ? '每条启用规则生成 1 注，数量与规则一致'
                : '请先在「输入」页完整填写 5 注号码',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 0.4,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppSpace.xl),
          const _OfficialDrawCard(),
          if (results.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Text(
                  '预测号码',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: AppSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fieldGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${results.length} 注',
                    style: const TextStyle(
                      color: AppColors.fieldGreen,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            ...List.generate(
              results.length,
              (i) => _ResultCard(
                index: i + 1,
                result: results[i],
                hit: state.hitOf(results[i].ticket),
                period: state.officialDraw.period,
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xl),
              child: Center(
                child: Text(
                  '点击上方按钮生成预测号码',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        letterSpacing: 0.5,
                        height: 1.6,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfficialDrawCard extends StatefulWidget {
  const _OfficialDrawCard();

  @override
  State<_OfficialDrawCard> createState() => _OfficialDrawCardState();
}

class _OfficialDrawCardState extends State<_OfficialDrawCard> {
  late final TextEditingController _periodCtrl;
  late final List<TextEditingController> _redCtrls;
  late final List<TextEditingController> _blueCtrls;

  @override
  void initState() {
    super.initState();
    final draw = context.read<AppState>().officialDraw;
    _periodCtrl = TextEditingController(text: draw.period);
    _redCtrls = List.generate(Ticket.redCount, (i) {
      final v = i < draw.ticket.reds.length ? draw.ticket.reds[i] : null;
      return TextEditingController(text: v == null ? '' : _pad(v));
    });
    _blueCtrls = List.generate(Ticket.blueCount, (i) {
      final v = i < draw.ticket.blues.length ? draw.ticket.blues[i] : null;
      return TextEditingController(text: v == null ? '' : _pad(v));
    });
  }

  @override
  void dispose() {
    _periodCtrl.dispose();
    for (final c in _redCtrls) {
      c.dispose();
    }
    for (final c in _blueCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _emit(AppState state) {
    final reds = <int>[];
    final blues = <int>[];
    for (final c in _redCtrls) {
      final n = int.tryParse(c.text.trim());
      if (n != null) reds.add(n);
    }
    for (final c in _blueCtrls) {
      final n = int.tryParse(c.text.trim());
      if (n != null) blues.add(n);
    }
    state.setOfficialDraw(
      period: _periodCtrl.text.trim(),
      ticket: Ticket(reds: reds, blues: blues).sorted(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ready = state.officialDraw.isReady;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_outlined,
                    color: AppColors.fieldGreen, size: 22),
                const SizedBox(width: AppSpace.sm),
                Text('开奖核对', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (ready)
                  Text(
                    '已就绪',
                    style: TextStyle(
                      color: AppColors.hit,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              '预测完成后，填写本期开奖号码，自动对照每注命中情况',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.55,
                    letterSpacing: 0.35,
                  ),
            ),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _periodCtrl,
              onChanged: (_) => _emit(state),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '期号',
                hintText: '例如 2026073',
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              '开奖红球',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.redBall,
                  ),
            ),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: List.generate(
                Ticket.redCount,
                (i) => _MiniNumField(
                  controller: _redCtrls[i],
                  accent: AppColors.redBall,
                  onChanged: (_) => _emit(state),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              '开奖蓝球',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.blueBall,
                  ),
            ),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: List.generate(
                Ticket.blueCount,
                (i) => _MiniNumField(
                  controller: _blueCtrls[i],
                  accent: AppColors.blueBall,
                  onChanged: (_) => _emit(state),
                ),
              ),
            ),
            if (ready) ...[
              const SizedBox(height: AppSpace.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: AppColors.fieldGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '第 ${state.officialDraw.period} 期开奖',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...state.officialDraw.ticket.reds.map(
                          (n) => BallChip(
                              number: n, kind: BallKind.red, size: 32),
                        ),
                        const Text('+',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        ...state.officialDraw.ticket.blues.map(
                          (n) => BallChip(
                              number: n, kind: BallKind.blue, size: 32),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _periodCtrl.clear();
                  for (final c in _redCtrls) {
                    c.clear();
                  }
                  for (final c in _blueCtrls) {
                    c.clear();
                  }
                  state.clearOfficialDraw();
                },
                child: const Text('清空开奖'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniNumField extends StatelessWidget {
  const _MiniNumField({
    required this.controller,
    required this.accent,
    required this.onChanged,
  });

  final TextEditingController controller;
  final Color accent;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 2,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: accent,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: accent.withValues(alpha: 0.06),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.index,
    required this.result,
    required this.hit,
    required this.period,
  });

  final int index;
  final RuleResult result;
  final HitCompare? hit;
  final String period;

  @override
  Widget build(BuildContext context) {
    final ticket = result.ticket;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    result.rule.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          letterSpacing: 0.45,
                          height: 1.35,
                        ),
                  ),
                ),
                Icon(
                  result.ok ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: result.ok ? AppColors.mint : AppColors.accent,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            if (ticket != null) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...ticket.reds.map(
                    (n) => BallChip(
                      number: n,
                      kind: BallKind.red,
                      size: 36,
                      selected: hit?.hitReds.contains(n) ?? false,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  ...ticket.blues.map(
                    (n) => BallChip(
                      number: n,
                      kind: BallKind.blue,
                      size: 36,
                      selected: hit?.hitBlues.contains(n) ?? false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              SelectableText(
                ticket.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
            ],
            if (hit != null) ...[
              const SizedBox(height: AppSpace.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: hit!.redHits + hit!.blueHits > 0
                      ? AppColors.hit.withValues(alpha: 0.1)
                      : AppColors.muted.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  period.isEmpty
                      ? '核对：红中 ${hit!.redHits} · 蓝中 ${hit!.blueHits} · ${hit!.prizeHint}'
                      : '第$period期核对：红中 ${hit!.redHits} · 蓝中 ${hit!.blueHits} · ${hit!.prizeHint}',
                  style: TextStyle(
                    color: hit!.redHits + hit!.blueHits > 0
                        ? AppColors.hit
                        : AppColors.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.45,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              ...result.warnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '· $w',
                    style: const TextStyle(
                      color: AppColors.redBall,
                      fontSize: 12,
                      height: 1.45,
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
              ),
            ],
            if (result.redDetail.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              const Text(
                '红球明细',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.redBall,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              ...result.redDetail.map(_detailLine),
            ],
            if (result.blueDetail.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              const Text(
                '蓝球明细',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueBall,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              ...result.blueDetail.map(_detailLine),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailLine(SlotDetail d) {
    final src =
        d.fromMissing ? '空 → 随机未出现号码' : '${d.source.label} → 原样取值';
    final val = d.value?.toString().padLeft(2, '0') ?? '—';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '位${d.outputIndex + 1}:  $val    $src',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.muted,
          height: 1.5,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}
