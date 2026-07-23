import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rule.dart';
import '../models/ticket.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ball_chip.dart';
import '../widgets/rule_editor.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  Future<void> _editRule(BuildContext context, AnalysisRule rule) async {
    final state = context.read<AppState>();
    final saved = await Navigator.of(context, rootNavigator: true)
        .push<AnalysisRule>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RuleEditPage(
          rule: rule.copy(),
          tickets: List<Ticket>.from(state.tickets),
        ),
      ),
    );
    if (saved != null && context.mounted) {
      state.updateRule(saved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('规则已保存')),
      );
    }
  }

  Future<void> _createRule(BuildContext context) async {
    final state = context.read<AppState>();
    state.addRule();
    await _editRule(context, state.rules.last);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('分析规则'),
        actions: [
          IconButton(
            tooltip: '添加规则',
            onPressed: () => _createRule(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: state.rules.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('暂无规则'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _createRule(context),
                    child: const Text('新建规则'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: state.rules.length,
              itemBuilder: (context, i) {
                final rule = state.rules[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rule.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Switch(
                              value: rule.enabled,
                              onChanged: (_) => state.toggleRule(rule.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('红球槽位',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: rule.redSlots.map((s) {
                            return BallChip(
                              number: null,
                              kind: s.isEmpty ? BallKind.empty : BallKind.red,
                              size: 30,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rule.redSlots.map((s) => s.label).join('  '),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted),
                        ),
                        const SizedBox(height: 10),
                        const Text('蓝球槽位',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: rule.blueSlots.map((s) {
                            return BallChip(
                              number: null,
                              kind: s.isEmpty ? BallKind.empty : BallKind.blue,
                              size: 30,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rule.blueSlots.map((s) => s.label).join('  '),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: FilledButton.icon(
                                  onPressed: () => _editRule(context, rule),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('编辑规则'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: '复制',
                              onPressed: () {
                                final dup = rule.copy(
                                  id: 'rule-${DateTime.now().millisecondsSinceEpoch}',
                                  name: '${rule.name} 副本',
                                );
                                state.addRule(dup);
                              },
                              icon: const Icon(Icons.copy),
                            ),
                            IconButton(
                              tooltip: '删除',
                              onPressed: () => state.removeRule(rule.id),
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.redBall),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: FloatingActionButton.extended(
          onPressed: () => _createRule(context),
          icon: const Icon(Icons.add),
          label: const Text('新建规则'),
        ),
      ),
    );
  }
}

class RuleEditPage extends StatefulWidget {
  const RuleEditPage({
    super.key,
    required this.rule,
    required this.tickets,
  });

  final AnalysisRule rule;
  final List<Ticket> tickets;

  @override
  State<RuleEditPage> createState() => _RuleEditPageState();
}

class _RuleEditPageState extends State<RuleEditPage> {
  late AnalysisRule _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.rule;
  }

  void _save() => Navigator.of(context).pop(_draft);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑规则'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            RuleEditor(
              rule: _draft,
              tickets: widget.tickets,
              onChanged: (r) => setState(() => _draft = r),
            ),
            const SizedBox(height: 24),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('保存规则'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
