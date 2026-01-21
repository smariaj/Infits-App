import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  static const String baseUrl = "http://10.169.30.216:3000";

  static Future<Map<String, dynamic>> fetchAgentLiveDashboard(int agentId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/dashboard/agent-live/$agentId"),
    );

    final body = json.decode(response.body);

    if (response.statusCode == 200 && body["success"] == true) {
      return body["data"];
    } else {
      throw Exception("Failed to load dashboard");
    }
  }
}
