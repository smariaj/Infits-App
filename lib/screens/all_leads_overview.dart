import 'package:flutter/material.dart';
import 'package:internship_app/models/lead_model.dart';
import 'package:internship_app/services/lead_service.dart';
import 'package:internship_app/screens/lead_and_activity_details.dart';
import 'package:internship_app/screens/fresh_leads_screen.dart';
import 'package:internship_app/screens/interested_leads.dart';
import 'package:internship_app/screens/contacted_leads_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';


class AllLeadsScreen extends StatefulWidget {
  const AllLeadsScreen({super.key});

  @override
  State<AllLeadsScreen> createState() => _AllLeadsScreenState();
}

class _AllLeadsScreenState extends State<AllLeadsScreen> {
  List<Lead> leads = [];
  bool isLoading = true;

  int? loggedInUserId;

  String selectedStatusFilter = "All";
  String searchQuery = "";

  List<String> statusFilters = [
    "All",
    "New Lead",
    "Interested",
    "Call Back",
    "Converted"
  ];

  @override
  void initState() {
    super.initState();
    loadUserAndLeads();
  }

  Future<void> loadUserAndLeads() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    loggedInUserId = prefs.getInt("user_id");

    if (loggedInUserId != null) {
      loadLeads();
    } else {
      setState(() => isLoading = false);
    }
  }

  void loadLeads() async {
    try {
      debugPrint("Fetching leads for user: $loggedInUserId");

      final data = await LeadService.getLeadsByAgent(loggedInUserId!);

      debugPrint("Leads fetched: ${data.length}");

      setState(() {
        leads = data;
        isLoading = false;
      });
    } catch (e, s) {
      debugPrint("LOAD LEADS ERROR: $e");
      debugPrintStack(stackTrace: s);

      setState(() => isLoading = false);
    }
  }


  Future<void> makeCall(String phone, int leadId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString("user_name") ?? "Unknown";

    final Uri callUri = Uri(
      scheme: 'tel',
      path: phone,
    );

    if (await canLaunchUrl(callUri)) {
      final launched = await launchUrl(callUri);

      if (launched) {
        await LeadService.logCallActivity(
          leadId: leadId,
          userName: userName,
        );
      }
    }
  }


  List<Lead> get filteredLeads {
    List<Lead> temp = leads;

    if (selectedStatusFilter != "All") {
      temp = temp.where((l) => l.status == selectedStatusFilter).toList();
    }

    if (searchQuery.isNotEmpty) {
      temp = temp.where((l) =>
      l.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (l.company ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
          l.phone.contains(searchQuery)).toList();
    }

    return temp;
  }

  Color statusColor(String status) {
    switch (status) {
      case 'New Lead':
        return Colors.blue;
      case 'Interested':
        return Colors.green;
      case 'Call Back':
        return Colors.orange;
      case 'Converted':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Leads',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.sort, color: Colors.blue),
            label: const Text('Sort', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _searchBar(),
            const SizedBox(height: 12),
            _statusFilters(),
            const SizedBox(height: 10),
            _dropdownFilters(),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLeads.isEmpty
                  ? const Center(child: Text("No leads assigned to you"))
                  : ListView.builder(
                itemCount: filteredLeads.length,
                itemBuilder: (context, index) {
                  final lead = filteredLeads[index];
                  return LeadCard(
                    name: lead.name,
                    subtitle: lead.company ?? 'No company',
                    status: lead.status,
                    statusColor: statusColor(lead.status),
                    timeText: lead.lastActivity,
                    onCallPressed: () {
                      makeCall(lead.phone, lead.id);
                    },
                    onChatPressed: () {},
                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LeadDetailsScreen(lead: lead,
                                onLeadUpdated: loadLeads,),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Leads'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Campaigns'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Call Stats'),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: const InputDecoration(
          icon: Icon(Icons.search),
          hintText: 'Search by name, company or phone...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _statusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statusFilters.map((status) {
          bool isSelected = selectedStatusFilter == status;
          return GestureDetector(
            onTap: () {
              if (status == "New Lead") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FreshLeadsScreen()),
                );
                return;
              }

              if (status == "Interested") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InterestedLeadsScreen()),
                );
                return;
              }

              if (status == "Call Back") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ContactedLeadsScreen()),
                );
                return;
              }

              // Converted & All → stay on same screen
              setState(() => selectedStatusFilter = status);
            },

            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _dropdownFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _dropdown('Campaign'),
          _dropdown('Date Added'),
          _dropdown('Priority'),
          _dropdown('Source'),
        ],
      ),
    );
  }

  Widget _dropdown(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(text, style: const TextStyle(fontSize: 12)),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
  }
}

class LeadCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String timeText;
  final VoidCallback onCallPressed;
  final VoidCallback onChatPressed;
  final VoidCallback onTap;

  const LeadCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.timeText,
    required this.onCallPressed,
    required this.onChatPressed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(fontSize: 10, color: statusColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeText,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble, color: Colors.green),
              onPressed: onChatPressed,
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.blue),
              onPressed: onCallPressed,
            ),
          ],
        ),
      ),
    );
  }
}
