import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ball_chip.dart';
import '../widgets/ticket_input.dart';

class InputScreen extends StatelessWidget {
  const InputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: AppColors.deepGreen,
            actions: [
              TextButton(
                onPressed: () {
                  state.clearTickets();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已清空全部号码')),
                  );
                },
                child: const Text('清空', style: TextStyle(color: Colors.white70)),
              ),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final settings = context
                    .dependOnInheritedWidgetOfExactType<
                        FlexibleSpaceBarSettings>();
                final min = settings?.minExtent ?? kToolbarHeight;
                final max = settings?.maxExtent ?? 140;
                final cur = settings?.currentExtent ?? max;
                final t = ((cur - min) / (max - min)).clamp(0.0, 1.0);

                return ClipRect(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.deepGreen, AppColors.fieldGreen],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            72,
                            12 + 6 * t,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (t > 0.35)
                                Opacity(
                                  opacity: ((t - 0.35) / 0.65).clamp(0.0, 1.0),
                                  child: Text(
                                    '体彩大乐透 · 前区 5 红 + 后区 2 蓝',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.82),
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              if (t > 0.35) SizedBox(height: 8 * t),
                              Text(
                                '输入 5 注号码',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18 + 4 * t,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i == 0) {
                    return _PoolSummary(state: state);
                  }
                  final idx = i - 1;
                  return TicketInputCard(
                    index: idx,
                    ticket: state.tickets[idx],
                    onChanged: (t) => state.setTicket(idx, t),
                  );
                },
                childCount: TicketInputCardCount.withSummary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TicketInputCardCount {
  static const withSummary = 1 + 5;
}

class _PoolSummary extends StatelessWidget {
  const _PoolSummary({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final ready = state.allTicketsReady;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ready ? Icons.verified : Icons.info_outline,
                  color: ready ? AppColors.mint : AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  ready ? '5 注已就绪' : '请完整填写 5 注号码',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (ready) ...[
              const SizedBox(height: 12),
              const Text('5 注未出现的红球（可供空位随机）',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: state.missingReds
                    .map((n) => BallChip(
                          number: n,
                          kind: BallKind.missing,
                          size: 28,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              const Text('5 注未出现的蓝球（可供空位随机）',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: state.missingBlues
                    .map((n) => BallChip(
                          number: n,
                          kind: BallKind.missing,
                          size: 28,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
