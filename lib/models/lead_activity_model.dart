class LeadActivity {
  final int id;
  final int leadId;
  final String type;
  final String title;
  final String? description;
  final String user;
  final DateTime createdAt;

  LeadActivity({
    required this.id,
    required this.leadId,
    required this.type,
    required this.title,
    this.description,
    required this.user,
    required this.createdAt,
  });

  factory LeadActivity.fromJson(Map<String, dynamic> json) {
    return LeadActivity(
      id: json['id'],
      leadId: json['lead_id'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      user: json['user'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
