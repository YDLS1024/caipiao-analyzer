import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/draw_check.dart';
import '../models/rule.dart';
import '../models/ticket.dart';
import '../services/rule_engine.dart';

class AppState extends ChangeNotifier {
  AppState() {
    tickets = List.generate(Ticket.inputTicketCount, (_) => Ticket.empty());
    rules = [AnalysisRule.sample('rule-sample')];
    officialDraw = OfficialDraw.empty();
  }

  static const _ticketsKey = 'tickets_v1';
  static const _rulesKey = 'rules_v1';
  static const _drawKey = 'official_draw_v1';

  late List<Ticket> tickets;
  late List<AnalysisRule> rules;
  late OfficialDraw officialDraw;

  final RuleEngine engine = RuleEngine();
  List<RuleResult> lastResults = const [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final tRaw = prefs.getString(_ticketsKey);
    final rRaw = prefs.getString(_rulesKey);
    final dRaw = prefs.getString(_drawKey);

    if (tRaw != null) {
      final list = jsonDecode(tRaw) as List<dynamic>;
      tickets = list
          .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
          .toList();
      while (tickets.length < Ticket.inputTicketCount) {
        tickets.add(Ticket.empty());
      }
      if (tickets.length > Ticket.inputTicketCount) {
        tickets = tickets.take(Ticket.inputTicketCount).toList();
      }
    }

    if (rRaw != null) {
      final list = jsonDecode(rRaw) as List<dynamic>;
      rules = list
          .map((e) => AnalysisRule.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (dRaw != null) {
      officialDraw =
          OfficialDraw.fromJson(jsonDecode(dRaw) as Map<String, dynamic>);
    }

    notifyListeners();
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ticketsKey,
      jsonEncode(tickets.map((t) => t.toJson()).toList()),
    );
    await prefs.setString(
      _rulesKey,
      jsonEncode(rules.map((r) => r.toJson()).toList()),
    );
    await prefs.setString(_drawKey, jsonEncode(officialDraw.toJson()));
  }

  void setTicket(int index, Ticket ticket) {
    // 未填完时不要排序，避免打乱输入框与号码的对应关系
    tickets[index] = ticket.isComplete ? ticket.sorted() : ticket;
    notifyListeners();
    persist();
  }

  void clearTickets() {
    tickets = List.generate(Ticket.inputTicketCount, (_) => Ticket.empty());
    lastResults = const [];
    notifyListeners();
    persist();
  }

  void setOfficialDraw({String? period, Ticket? ticket}) {
    officialDraw = officialDraw.copyWith(period: period, ticket: ticket);
    notifyListeners();
    persist();
  }

  void clearOfficialDraw() {
    officialDraw = OfficialDraw.empty();
    notifyListeners();
    persist();
  }

  void addRule([AnalysisRule? rule]) {
    final id = 'rule-${DateTime.now().millisecondsSinceEpoch}';
    rules.add(
      rule ??
          AnalysisRule(
            id: id,
            name: '规则 ${rules.length + 1}',
          ),
    );
    notifyListeners();
    persist();
  }

  void updateRule(AnalysisRule rule) {
    final i = rules.indexWhere((r) => r.id == rule.id);
    if (i < 0) return;
    rules[i] = rule;
    notifyListeners();
    persist();
  }

  void removeRule(String id) {
    rules.removeWhere((r) => r.id == id);
    notifyListeners();
    persist();
  }

  void toggleRule(String id) {
    final i = rules.indexWhere((r) => r.id == id);
    if (i < 0) return;
    rules[i].enabled = !rules[i].enabled;
    notifyListeners();
    persist();
  }

  bool get allTicketsReady => tickets.every((t) => t.isComplete);

  int get enabledRuleCount => rules.where((r) => r.enabled).length;

  Set<int> get usedReds {
    final s = <int>{};
    for (final t in tickets) {
      s.addAll(t.reds);
    }
    return s;
  }

  Set<int> get usedBlues {
    final s = <int>{};
    for (final t in tickets) {
      s.addAll(t.blues);
    }
    return s;
  }

  List<int> get missingReds => [
        for (var n = Ticket.redMin; n <= Ticket.redMax; n++)
          if (!usedReds.contains(n)) n,
      ];

  List<int> get missingBlues => [
        for (var n = Ticket.blueMin; n <= Ticket.blueMax; n++)
          if (!usedBlues.contains(n)) n,
      ];

  /// 一条启用规则对应生成一注号码
  List<RuleResult> analyze() {
    lastResults = engine.applyAll(tickets: tickets, rules: rules);
    notifyListeners();
    return lastResults;
  }

  HitCompare? hitOf(Ticket? predicted) {
    if (predicted == null || !officialDraw.isReady) return null;
    return HitCompare.compare(predicted, officialDraw.ticket);
  }
}
