// lead_model.dart
class Lead {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? company;
  String status;
  final String lastActivity;
  final String campaignId;

  Lead({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.company,
    required this.status,
    required this.lastActivity,
    required this.campaignId,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      company: json['company'],
      status: json['status'],
      lastActivity: json['last_activity'],
      campaignId: json['campaign_id'].toString(),
    );
  }
}