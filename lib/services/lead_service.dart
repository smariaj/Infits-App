import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:internship_app/models/lead_model.dart';
import 'package:internship_app/models/lead_activity_model.dart';


class LeadService {
  static const String baseUrl = 'http://10.35.68.59:3000';

  static Future<List<Lead>> getLeadsByAgent(int agentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/leads?agent_id=$agentId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      return (decoded['data'] as List)
          .map((e) => Lead.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to fetch leads');
    }
  }

  static Future<void> logCallActivity({
    required int leadId,
    required String userName,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/lead-activities"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "lead_id": leadId,
        "type": "call",
        "title": "Outgoing call",
        "description": "Call initiated from mobile app",
        "user": userName,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Failed to log call activity");
    }
  }

  static Future<List<LeadActivity>> getLeadActivities(int leadId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/lead_activities/lead-activities?lead_id=$leadId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      return data.map<LeadActivity>((e) => LeadActivity.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch lead activities');
    }
  }

  static Future<void> updateLeadStatus(int leadId, String newStatus) async {
    final response = await http.put(
      Uri.parse('$baseUrl/leads/$leadId'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': newStatus,
      }),
    );

    if (response.statusCode != 200) {
      print('Update status error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to update lead status');
    }
  }


}
