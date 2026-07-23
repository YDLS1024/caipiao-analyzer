/// 体彩大乐透一注：前区 5 红球 (1-35) + 后区 2 蓝球 (1-12)
class Ticket {
  const Ticket({
    required this.reds,
    required this.blues,
  });

  static const int redCount = 5;
  static const int blueCount = 2;
  static const int redMin = 1;
  static const int redMax = 35;
  static const int blueMin = 1;
  static const int blueMax = 12;
  static const int inputTicketCount = 5;

  /// 红球，长度应为 5，升序存储
  final List<int> reds;

  /// 蓝球，长度应为 2，升序存储
  final List<int> blues;

  bool get isComplete =>
      reds.length == redCount &&
      blues.length == blueCount &&
      reds.toSet().length == redCount &&
      blues.toSet().length == blueCount &&
      reds.every((n) => n >= redMin && n <= redMax) &&
      blues.every((n) => n >= blueMin && n <= blueMax);

  bool get isEmpty => reds.isEmpty && blues.isEmpty;

  Ticket sorted() => Ticket(
        reds: [...reds]..sort(),
        blues: [...blues]..sort(),
      );

  Ticket copyWith({List<int>? reds, List<int>? blues}) => Ticket(
        reds: reds ?? this.reds,
        blues: blues ?? this.blues,
      );

  Map<String, dynamic> toJson() => {
        'reds': reds,
        'blues': blues,
      };

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        reds: (json['reds'] as List<dynamic>).map((e) => e as int).toList(),
        blues: (json['blues'] as List<dynamic>).map((e) => e as int).toList(),
      );

  factory Ticket.empty() => const Ticket(reds: [], blues: []);

  @override
  String toString() {
    final r = reds.map(_pad).join(' ');
    final b = blues.map(_pad).join(' ');
    return '$r + $b';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ticket &&
          _listEq(reds, other.reds) &&
          _listEq(blues, other.blues);

  @override
  int get hashCode => Object.hash(Object.hashAll(reds), Object.hashAll(blues));

  static bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
