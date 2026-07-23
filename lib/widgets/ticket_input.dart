import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ticket.dart';
import '../theme/app_theme.dart';
import 'ball_chip.dart';

/// 单注大乐透号码输入（5 红 + 2 蓝）
class TicketInputCard extends StatefulWidget {
  const TicketInputCard({
    super.key,
    required this.index,
    required this.ticket,
    required this.onChanged,
  });

  final int index;
  final Ticket ticket;
  final ValueChanged<Ticket> onChanged;

  @override
  State<TicketInputCard> createState() => _TicketInputCardState();
}

class _TicketInputCardState extends State<TicketInputCard> {
  late final List<TextEditingController> _redCtrls;
  late final List<TextEditingController> _blueCtrls;
  late final List<FocusNode> _redFocus;
  late final List<FocusNode> _blueFocus;
  String? _error;

  @override
  void initState() {
    super.initState();
    _redCtrls = List.generate(Ticket.redCount, (i) {
      final v = i < widget.ticket.reds.length ? widget.ticket.reds[i] : null;
      return TextEditingController(text: v == null ? '' : _pad(v));
    });
    _blueCtrls = List.generate(Ticket.blueCount, (i) {
      final v = i < widget.ticket.blues.length ? widget.ticket.blues[i] : null;
      return TextEditingController(text: v == null ? '' : _pad(v));
    });
    _redFocus = List.generate(Ticket.redCount, (_) => FocusNode());
    _blueFocus = List.generate(Ticket.blueCount, (_) => FocusNode());
    for (final f in _redFocus) {
      f.addListener(() => _onFocusChange(isRed: true));
    }
    for (final f in _blueFocus) {
      f.addListener(() => _onFocusChange(isRed: false));
    }
  }

  @override
  void didUpdateWidget(covariant TicketInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticket == widget.ticket) return;

    final editing = _redFocus.any((f) => f.hasFocus) ||
        _blueFocus.any((f) => f.hasFocus);
    if (editing) return;

    // 清空
    if (widget.ticket.isEmpty) {
      for (final c in _redCtrls) {
        c.text = '';
      }
      for (final c in _blueCtrls) {
        c.text = '';
      }
      return;
    }

    // 仅在完整一注时回写（避免输入过程中把 1 补成 01）
    if (!widget.ticket.isComplete) return;

    for (var i = 0; i < Ticket.redCount; i++) {
      final text = _pad(widget.ticket.reds[i]);
      if (_redCtrls[i].text != text) _redCtrls[i].text = text;
    }
    for (var i = 0; i < Ticket.blueCount; i++) {
      final text = _pad(widget.ticket.blues[i]);
      if (_blueCtrls[i].text != text) _blueCtrls[i].text = text;
    }
  }

  @override
  void dispose() {
    for (final f in _redFocus) {
      f.dispose();
    }
    for (final f in _blueFocus) {
      f.dispose();
    }
    for (final c in _redCtrls) {
      c.dispose();
    }
    for (final c in _blueCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _onFocusChange({required bool isRed}) {
    final focuses = isRed ? _redFocus : _blueFocus;
    final ctrls = isRed ? _redCtrls : _blueCtrls;
    for (var i = 0; i < focuses.length; i++) {
      if (focuses[i].hasFocus) continue;
      final raw = ctrls[i].text.trim();
      if (raw.isEmpty) continue;
      final n = int.tryParse(raw);
      if (n == null) continue;
      final padded = _pad(n);
      if (ctrls[i].text != padded) {
        ctrls[i].value = TextEditingValue(
          text: padded,
          selection: TextSelection.collapsed(offset: padded.length),
        );
      }
    }
    _emit();
  }

  void _emit() {
    final reds = <int>[];
    final blues = <int>[];
    String? err;

    for (final c in _redCtrls) {
      final t = c.text.trim();
      if (t.isEmpty) continue;
      final n = int.tryParse(t);
      if (n == null || n < Ticket.redMin || n > Ticket.redMax) {
        err = '红球须为 ${Ticket.redMin}-${Ticket.redMax}';
        continue;
      }
      reds.add(n);
    }
    for (final c in _blueCtrls) {
      final t = c.text.trim();
      if (t.isEmpty) continue;
      final n = int.tryParse(t);
      if (n == null || n < Ticket.blueMin || n > Ticket.blueMax) {
        err = '蓝球须为 ${Ticket.blueMin}-${Ticket.blueMax}';
        continue;
      }
      blues.add(n);
    }

    if (reds.isNotEmpty && reds.length != reds.toSet().length) {
      err = '红球不能重复';
    }
    if (blues.isNotEmpty && blues.length != blues.toSet().length) {
      err = '蓝球不能重复';
    }

    setState(() => _error = err);
    // 有重复时仍回传，但标记错误；完整且无错才算有效一注
    widget.onChanged(Ticket(reds: reds, blues: blues));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '第 ${widget.index + 1} 注',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.ticket.isComplete)
                  const Icon(Icons.check_circle,
                      color: AppColors.mint, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '前区红球 (01-35)，每位可输入两位数',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.35,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                Ticket.redCount,
                (i) => _NumField(
                  controller: _redCtrls[i],
                  focusNode: _redFocus[i],
                  accent: AppColors.redBall,
                  onChanged: (_) => _emit(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '后区蓝球 (01-12)，每位可输入两位数',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.35,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                Ticket.blueCount,
                (i) => _NumField(
                  controller: _blueCtrls[i],
                  focusNode: _blueFocus[i],
                  accent: AppColors.blueBall,
                  onChanged: (_) => _emit(),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.redBall.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.redBall.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.redBall,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
            if (widget.ticket.isComplete) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...widget.ticket.reds.map(
                    (n) => BallChip(number: n, kind: BallKind.red, size: 28),
                  ),
                  ...widget.ticket.blues.map(
                    (n) => BallChip(number: n, kind: BallKind.blue, size: 28),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.controller,
    required this.focusNode,
    required this.accent,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accent;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        textAlign: TextAlign.center,
        maxLength: 2,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: accent,
          fontSize: 18,
          letterSpacing: 1.0,
          height: 1.2,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: '00',
          hintStyle: TextStyle(
            color: accent.withValues(alpha: 0.25),
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: accent.withValues(alpha: 0.06),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: accent, width: 1.6),
          ),
        ),
      ),
    );
  }
}
