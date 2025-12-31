import 'package:internship_app/models/campaign.dart';

class CampaignRepository {
  static List<Campaign> getCampaigns() {
    return [
      Campaign(
        id: "1",
        title: "Q4 SaaS Outreach",
        status: "Active",
        audience: "CTOs in FinTech",
        called: 65,
        target: 100,
        startDate: DateTime(2024, 10, 1),
        dueDate: DateTime(2024, 12, 31),
      ),
      Campaign(
        id: "2",
        title: "Cold Leads Reactivation",
        status: "Paused",
        audience: "Retail Managers",
        called: 12,
        target: 100,
        startDate: DateTime(2024, 9, 15),
        dueDate: DateTime(2024, 11, 15),
      ),
      Campaign(
        id: "3",
        title: "Webinar Follow-up",
        status: "Draft",
        audience: "Recent Registrants",
        called: 0,
        target: 50,
        startDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
      ),
    ];
  }
}
