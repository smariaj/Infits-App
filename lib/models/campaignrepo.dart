import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'campaign.dart';

class CampaignRepository {
  static Future<List<Campaign>> fetchCampaignsForAgent(String agentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";

    final response = await http.get(
      Uri.parse("http://10.35.68.59:3000/campaigns?agentId=$agentId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded['data'] ?? [];

      // Filter only campaigns assigned to this agent
      final assigned = data.where((c) => (c['agent_count'] ?? 0) > 0).toList();

      return assigned.map((c) => Campaign.fromJson(c)).toList();
    } else {
      throw Exception("Failed to load campaigns");
    }
  }
}
