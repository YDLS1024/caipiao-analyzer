import '../models/ticket.dart';

/// 某期开奖号码（用于核对预测）
class OfficialDraw {
  const OfficialDraw({
    required this.period,
    required this.ticket,
  });

  /// 期号，如 2026073
  final String period;
  final Ticket ticket;

  bool get isReady => period.trim().isNotEmpty && ticket.isComplete;

  OfficialDraw copyWith({String? period, Ticket? ticket}) => OfficialDraw(
        period: period ?? this.period,
        ticket: ticket ?? this.ticket,
      );

  Map<String, dynamic> toJson() => {
        'period': period,
        'ticket': ticket.toJson(),
      };

  factory OfficialDraw.fromJson(Map<String, dynamic> json) => OfficialDraw(
        period: json['period'] as String? ?? '',
        ticket: Ticket.fromJson(json['ticket'] as Map<String, dynamic>),
      );

  factory OfficialDraw.empty() =>
      OfficialDraw(period: '', ticket: Ticket.empty());
}

/// 预测号与开奖号的命中结果
class HitCompare {
  const HitCompare({
    required this.redHits,
    required this.blueHits,
    required this.hitReds,
    required this.hitBlues,
  });

  final int redHits;
  final int blueHits;
  final List<int> hitReds;
  final List<int> hitBlues;

  /// 简要奖级提示（大乐透常见档）
  String get prizeHint {
    final r = redHits;
    final b = blueHits;
    if (r == 5 && b == 2) return '一等奖';
    if (r == 5 && b == 1) return '二等奖';
    if (r == 5 && b == 0) return '三等奖';
    if (r == 4 && b == 2) return '四等奖';
    if (r == 4 && b == 1) return '五等奖';
    if ((r == 3 && b == 2) || (r == 4 && b == 0)) return '六等奖';
    if ((r == 3 && b == 1) || (r == 2 && b == 2)) return '七等奖';
    if ((r == 3 && b == 0) ||
        (r == 2 && b == 1) ||
        (r == 1 && b == 2) ||
        (r == 0 && b == 2)) {
      return '八等奖';
    }
    if ((r == 2 && b == 0) || (r == 1 && b == 1) || (r == 0 && b == 1)) {
      return '九等奖';
    }
    return '未中奖';
  }

  static HitCompare compare(Ticket predicted, Ticket official) {
    final oReds = official.reds.toSet();
    final oBlues = official.blues.toSet();
    final hitReds = predicted.reds.where(oReds.contains).toList();
    final hitBlues = predicted.blues.where(oBlues.contains).toList();
    return HitCompare(
      redHits: hitReds.length,
      blueHits: hitBlues.length,
      hitReds: hitReds,
      hitBlues: hitBlues,
    );
  }
}
