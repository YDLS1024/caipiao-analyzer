import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/history_record.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ball_chip.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _fmtTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: '清空历史',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('清空全部历史？'),
                    content: const Text('此操作不可恢复'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await state.clearHistory();
                }
              },
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              '存储：${state.storageBackendLabel} · 共 ${items.length} 条',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    letterSpacing: 0.4,
                    height: 1.45,
                  ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      '暂无历史\n在「分析」页生成号码后点「保存到历史」',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.6,
                            letterSpacing: 0.4,
                          ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => HistoryDetailPage(record: item),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    Text(
                                      _fmtTime(item.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '预测 ${item.predictions.length} 注'
                                  '${item.hasOfficial ? ' · 已核对开奖' : ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(letterSpacing: 0.35),
                                ),
                                if (item.predictions.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      ...item.predictions.first.ticket.reds
                                          .map(
                                        (n) => BallChip(
                                          number: n,
                                          kind: BallKind.red,
                                          size: 28,
                                        ),
                                      ),
                                      const Text('+',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w800)),
                                      ...item.predictions.first.ticket.blues
                                          .map(
                                        (n) => BallChip(
                                          number: n,
                                          kind: BallKind.blue,
                                          size: 28,
                                        ),
                                      ),
                                      if (item.predictions.length > 1)
                                        Text(
                                          ' 等${item.predictions.length}注',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                    ],
                                  ),
                                ],
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    tooltip: '删除',
                                    onPressed: item.id == null
                                        ? null
                                        : () => state.deleteHistory(item.id!),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.redBall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({super.key, required this.record});

  final HistoryRecord record;

  String _fmtTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final item = record;
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            _fmtTime(item.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (item.hasOfficial) ...[
            const SizedBox(height: 16),
            const Text('开奖号码',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                ...item.officialTicket!.reds.map(
                  (n) => BallChip(number: n, kind: BallKind.red, size: 32),
                ),
                const Text('+'),
                ...item.officialTicket!.blues.map(
                  (n) => BallChip(number: n, kind: BallKind.blue, size: 32),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text('预测号码',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          const SizedBox(height: 8),
          ...item.predictions.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.ruleName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...p.ticket.reds.map(
                        (n) => BallChip(
                          number: n,
                          kind: BallKind.red,
                          size: 32,
                          selected: item.officialTicket?.reds.contains(n) ?? false,
                        ),
                      ),
                      const Text('+'),
                      ...p.ticket.blues.map(
                        (n) => BallChip(
                          number: n,
                          kind: BallKind.blue,
                          size: 32,
                          selected:
                              item.officialTicket?.blues.contains(n) ?? false,
                        ),
                      ),
                    ],
                  ),
                  if (p.prizeHint != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '红中 ${p.redHits} · 蓝中 ${p.blueHits} · ${p.prizeHint}',
                      style: const TextStyle(
                        color: AppColors.hit,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
