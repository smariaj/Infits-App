import 'package:flutter/material.dart';
import 'package:internship_app/models/lead_model.dart';
import 'package:internship_app/services/lead_service.dart';
import 'package:internship_app/screens/lead_and_activity_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:internship_app/screens/campaign_progess_notifier.dart';

class FreshLeadsScreen extends StatefulWidget {
  const FreshLeadsScreen({super.key});

  @override
  State<FreshLeadsScreen> createState() => _FreshLeadsScreenState();
}

class _FreshLeadsScreenState extends State<FreshLeadsScreen> {
  List<Lead> leads = [];
  bool isLoading = true;
  int? agentId;

  @override
  void initState() {
    super.initState();
    fetchFreshLeads();
  }

  Future<void> fetchFreshLeads() async {
    setState(() => isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      agentId = prefs.getInt("user_id");

      if (agentId == null) {
        setState(() => isLoading = false);
        return;
      }

      final allLeads = await LeadService.getLeadsByAgent(agentId!);

      setState(() {
        leads = allLeads.where((l) => l.status == 'New Lead').toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching fresh leads: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> makeCall(Lead lead) async {
    final phone = lead.phone;
    if (phone.isEmpty) return;

    final Uri callUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(callUri)) {
      final launched = await launchUrl(callUri);
      if (launched) {
        // Log call activity with user ID and name
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt("user_id");
        final userName = prefs.getString("user_name");

        if (userId != null && userName != null) {
          await LeadService.logCallActivity(
            leadId: lead.id,
            userId: userId,
            user: userName, // <-- send the name to backend
          );
        }

        // Notify campaign screen to refresh
        if (lead.campaignId != null) {
          final intId = int.tryParse(lead.campaignId!);
          if (intId != null) {
            campaignProgressNotifier.markUpdated(intId);
          }
        }

        // Refresh the fresh leads list
        fetchFreshLeads();
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot open dialer")),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 2),
            Text(
              'Fresh Leads',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manage your daily targets',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: Text(
              'AM',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: 'Search by name, number or tag...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              Row(
                children: [
                  _filterChip('All Leads', selected: true),
                  const SizedBox(width: 8),
                  _filterChip('Priority'),
                  const SizedBox(width: 8),
                  _filterChip('Newest'),
                ],
              ),
              const SizedBox(height: 20),

              // Today's Queue
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Today's Queue",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'View All',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lead List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : leads.isEmpty
                    ? const Center(
                  child: Text("No fresh leads assigned to you"),
                )
                    : ListView.builder(
                  itemCount: leads.length,
                  itemBuilder: (context, index) {
                    final lead = leads[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LeadDetailsScreen(
                              lead: lead,
                              onLeadUpdated: fetchFreshLeads,
                            ),
                          ),
                        );
                      },
                      child: _leadCard(
                        initials: lead.name.isNotEmpty
                            ? lead.name
                            .trim()
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join()
                            : '',
                        name: lead.name,
                        subtitle:
                        '${lead.company ?? 'Unknown'} • ${lead.lastActivity ?? 'N/A'}',
                        status: 'New',
                        primaryButton: 'Call Lead',
                        onCallPressed: () => makeCall(lead),
                      ),
                    );
                  },
                ),
              ),

              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "You've reached the end of the list",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

     /* bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Leads'),
          BottomNavigationBarItem(
              icon: Icon(Icons.campaign), label: 'Campaigns'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Call Stats'),
        ],
      ),*/
    );
  }

  // 🔹 Filter Chip Widget
  static Widget _filterChip(String text, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontSize: 12,
        ),
      ),
    );
  }

  // 🔹 Lead Card Widget
  static Widget _leadCard({
    required String initials,
    required String name,
    required String subtitle,
    required String status,
    required String primaryButton,
    required VoidCallback onCallPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Text(initials),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onCallPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Text(primaryButton),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
