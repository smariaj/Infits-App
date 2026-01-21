import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'campaign.dart';

class CampaignRepository {
  /// Fetch campaigns for a given agent
  static Future<List<Campaign>> fetchCampaignsForAgent(String agentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";

    final url = "http://10.169.30.216:3000/campaigns?agentId=$agentId";
    print("DEBUG FETCH URL: $url");
    print("DEBUG HEADERS: {Content-Type: application/json, Authorization: Bearer $token}");

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("DEBUG STATUS CODE: ${response.statusCode}");
    print("DEBUG RESPONSE BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded['data'] ?? [];

      // 🔴 DEBUG 1: raw API data
      print("DEBUG RAW CAMPAIGNS: $data");

      if (data.isNotEmpty) {
        print("DEBUG CAMPAIGN KEYS: ${data[0].keys}");
      }

      // 🔴 DEBUG 2: agent_count values
      for (var c in data) {
        print("DEBUG agent_count: ${c['agent_count']}");
      }

      // Filter only campaigns **assigned to this agent**
      final assigned = data.where((c) {
        // If your API returns assigned agent IDs, check that instead
        // Example: (c['assigned_agents'] ?? []).contains(agentId)
        return (c['agent_count'] ?? 0) > 0;
      }).toList();

      for (var c in assigned) {
        print("DEBUG Campaign ${c['id']} - called: ${c['called']} (type: ${c['called']?.runtimeType})");
      }

      // 🔄 Ensure we always parse the latest `called` count
      return assigned.map((c) => Campaign.fromJson(c)).toList();

    } else {
      throw Exception("Failed to load campaigns");
    }
  }
}
