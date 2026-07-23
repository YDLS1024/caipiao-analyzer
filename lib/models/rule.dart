/// 规则中某一个输出位置的来源
///
/// - 例如 `①1`：第 1 注的第 1 个号码（[ticketIndex]=0, [position]=0）
/// - 空位：随机取一个不在当前 5 注同色号码中的数（并尽量符合升序）
class SlotSource {
  const SlotSource({this.ticketIndex, this.position});

  /// 空位
  const SlotSource.empty()
      : ticketIndex = null,
        position = null;

  /// 引用：第 [ticketIndex] 注（0-based）的第 [position] 个球（0-based）
  const SlotSource.ref(this.ticketIndex, this.position);

  static const circled = ['①', '②', '③', '④', '⑤'];

  final int? ticketIndex;
  final int? position;

  bool get isEmpty => ticketIndex == null || position == null;

  bool get isRef => !isEmpty;

  /// 展示标签：空 / ①1 / ②3 …
  String get label {
    if (isEmpty) return '空';
    final t = ticketIndex!;
    final p = position!;
    final head = (t >= 0 && t < circled.length) ? circled[t] : '第${t + 1}注';
    return '$head${p + 1}';
  }

  Map<String, dynamic> toJson() => {
        'ticketIndex': ticketIndex,
        'position': position,
      };

  factory SlotSource.fromJson(Map<String, dynamic> json) {
    final t = json['ticketIndex'] as int?;
    final p = json['position'] as int?;
    if (t == null || p == null) return const SlotSource.empty();
    return SlotSource.ref(t, p);
  }

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotSource &&
          ticketIndex == other.ticketIndex &&
          position == other.position;

  @override
  int get hashCode => Object.hash(ticketIndex, position);
}

/// 一条分析规则：红球与蓝球规则互不跨越
class AnalysisRule {
  AnalysisRule({
    required this.id,
    required this.name,
    List<SlotSource>? redSlots,
    List<SlotSource>? blueSlots,
    this.enabled = true,
  })  : redSlots = List<SlotSource>.from(
          redSlots ??
              List.generate(5, (_) => const SlotSource.empty()),
        ),
        blueSlots = List<SlotSource>.from(
          blueSlots ??
              List.generate(2, (_) => const SlotSource.empty()),
        );

  final String id;
  String name;

  /// 红球 5 个输出位的来源（只引用红球，不跨越蓝球）
  List<SlotSource> redSlots;

  /// 蓝球 2 个输出位的来源（只引用蓝球，不跨越红球）
  List<SlotSource> blueSlots;

  bool enabled;

  AnalysisRule copy({String? id, String? name}) => AnalysisRule(
        id: id ?? this.id,
        name: name ?? this.name,
        redSlots: redSlots.map((s) => SlotSource.fromJson(s.toJson())).toList(),
        blueSlots:
            blueSlots.map((s) => SlotSource.fromJson(s.toJson())).toList(),
        enabled: enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'redSlots': redSlots.map((s) => s.toJson()).toList(),
        'blueSlots': blueSlots.map((s) => s.toJson()).toList(),
        'enabled': enabled,
      };

  factory AnalysisRule.fromJson(Map<String, dynamic> json) => AnalysisRule(
        id: json['id'] as String,
        name: json['name'] as String,
        redSlots: (json['redSlots'] as List<dynamic>)
            .map((e) => SlotSource.fromJson(e as Map<String, dynamic>))
            .toList(),
        blueSlots: (json['blueSlots'] as List<dynamic>)
            .map((e) => SlotSource.fromJson(e as Map<String, dynamic>))
            .toList(),
        enabled: json['enabled'] as bool? ?? true,
      );

  /// 默认示例：①1 ②2 ③3 ④4 空 + 蓝球 ①1 ②2
  factory AnalysisRule.sample(String id) => AnalysisRule(
        id: id,
        name: '示例：①1②2③3④4空',
        redSlots: const [
          SlotSource.ref(0, 0), // ①1
          SlotSource.ref(1, 1), // ②2
          SlotSource.ref(2, 2), // ③3
          SlotSource.ref(3, 3), // ④4
          SlotSource.empty(), // 空：随机未出现且尽量升序
        ],
        blueSlots: const [
          SlotSource.ref(0, 0), // ①1
          SlotSource.ref(1, 1), // ②2
        ],
      );
}
