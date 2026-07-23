import 'dart:convert';

import 'draw_check.dart';
import 'ticket.dart';

/// 单条预测明细（写入历史）
class HistoryPrediction {
  const HistoryPrediction({
    required this.ruleId,
    required this.ruleName,
    required this.ticket,
    required this.ok,
    this.warnings = const [],
    this.redHits,
    this.blueHits,
    this.prizeHint,
  });

  final String ruleId;
  final String ruleName;
  final Ticket ticket;
  final bool ok;
  final List<String> warnings;
  final int? redHits;
  final int? blueHits;
  final String? prizeHint;

  Map<String, dynamic> toJson() => {
        'ruleId': ruleId,
        'ruleName': ruleName,
        'ticket': ticket.toJson(),
        'ok': ok,
        'warnings': warnings,
        'redHits': redHits,
        'blueHits': blueHits,
        'prizeHint': prizeHint,
      };

  factory HistoryPrediction.fromJson(Map<String, dynamic> json) =>
      HistoryPrediction(
        ruleId: json['ruleId'] as String? ?? '',
        ruleName: json['ruleName'] as String? ?? '',
        ticket: Ticket.fromJson(json['ticket'] as Map<String, dynamic>),
        ok: json['ok'] as bool? ?? true,
        warnings: (json['warnings'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        redHits: json['redHits'] as int?,
        blueHits: json['blueHits'] as int?,
        prizeHint: json['prizeHint'] as String?,
      );
}

/// 一局分析历史（SQLite 一行）
class HistoryRecord {
  const HistoryRecord({
    this.id,
    required this.createdAt,
    required this.period,
    required this.inputTickets,
    required this.predictions,
    this.officialTicket,
    this.note = '',
  });

  final int? id;
  final DateTime createdAt;

  /// 期号（可空字符串表示未填）
  final String period;
  final List<Ticket> inputTickets;
  final List<HistoryPrediction> predictions;
  final Ticket? officialTicket;
  final String note;

  bool get hasOfficial => officialTicket != null && officialTicket!.isComplete;

  String get title {
    if (period.trim().isNotEmpty) return '第 $period 期';
    return '未填期号';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'period': period,
        'inputTickets': inputTickets.map((t) => t.toJson()).toList(),
        'predictions': predictions.map((p) => p.toJson()).toList(),
        'officialTicket': officialTicket?.toJson(),
        'note': note,
      };

  factory HistoryRecord.fromJson(Map<String, dynamic> json) => HistoryRecord(
        id: json['id'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        period: json['period'] as String? ?? '',
        inputTickets: (json['inputTickets'] as List<dynamic>)
            .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
            .toList(),
        predictions: (json['predictions'] as List<dynamic>)
            .map((e) => HistoryPrediction.fromJson(e as Map<String, dynamic>))
            .toList(),
        officialTicket: json['officialTicket'] == null
            ? null
            : Ticket.fromJson(json['officialTicket'] as Map<String, dynamic>),
        note: json['note'] as String? ?? '',
      );

  /// 从当前分析结果构造
  factory HistoryRecord.fromAnalysis({
    required List<Ticket> inputTickets,
    required OfficialDraw draw,
    required List<HistoryPrediction> predictions,
  }) {
    return HistoryRecord(
      createdAt: DateTime.now(),
      period: draw.period.trim(),
      inputTickets: List<Ticket>.from(inputTickets),
      predictions: predictions,
      officialTicket: draw.isReady ? draw.ticket : null,
    );
  }

  String encodePayload() => jsonEncode(toJson());
}
