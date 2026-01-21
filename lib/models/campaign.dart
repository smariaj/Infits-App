class Campaign {
  final String id;
  final String title;
  final String status;
  final String demographics;
  final int called;
  final int target;
  final DateTime startDate;
  final DateTime dueDate;
  final int agentCount;

  Campaign({
    required this.id,
    required this.title,
    required this.status,
    required this.demographics, // <- string
    required this.called,
    required this.target,
    required this.startDate,
    required this.dueDate,
    required this.agentCount,
  });

  double get progress => target == 0 ? 0 : called / target;

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'].toString(),
      title: json['campaign_name'] ?? '',
      status: json['status'] ?? 'Draft',
      demographics: json['demographics']?.toString() ?? '',
      called: int.tryParse(json['called']?.toString() ?? '0') ?? 0,
      target: int.tryParse(json['target']?.toString() ?? '100') ?? 100,

      startDate: DateTime.parse(json['start_date']),
      dueDate: DateTime.parse(json['end_date']),
      agentCount: int.tryParse(json['agent_count']?.toString() ?? '0') ?? 0,
    );
  }
}
