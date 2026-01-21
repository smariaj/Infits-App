import 'package:flutter/material.dart';
import 'package:internship_app/models/lead_model.dart';
import 'package:internship_app/services/lead_service.dart';
import 'package:internship_app/screens/lead_and_activity_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:internship_app/screens/campaign_progess_notifier.dart';

class InterestedLeadsScreen extends StatefulWidget {
  const InterestedLeadsScreen({super.key});

  @override
  State<InterestedLeadsScreen> createState() => _InterestedLeadsScreenState();
}

class _InterestedLeadsScreenState extends State<InterestedLeadsScreen> {
  List<Lead> leads = [];
  List<Lead> filteredLeads = [];
  bool isLoading = true;
  int? agentId;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadUserAndLeads();
  }

  Future<void> loadUserAndLeads() async {
    final prefs = await SharedPreferences.getInstance();
    agentId = prefs.getInt("user_id");

    if (agentId != null) {
      fetchInterestedLeads();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchInterestedLeads() async {
    try {
      final allLeads = await LeadService.getLeadsByAgent(agentId!);
      final interested = allLeads
          .where((l) => l.status.toLowerCase().contains('interested'))
          .toList();

      setState(() {
        leads = interested;
        filteredLeads = interested;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void filterLeads(String value) {
    setState(() {
      searchQuery = value;
      filteredLeads = leads
          .where((l) =>
          l.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    });
  }

  Future<void> makeCall(Lead lead) async {
    final phone = lead.phone;
    if (phone.isEmpty) return;

    final Uri callUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(callUri)) {
      final launched = await launchUrl(callUri);
      if (launched) {
        // Log call activity
        final prefs = await SharedPreferences.getInstance();
        final userName = prefs.getString("user_name") ?? "Unknown";

        await LeadService.logCallActivity(
          leadId: lead.id,
          userName: userName,
        );

        // Notify campaign screen to refresh
        if (lead.campaignId != null) {
          final intId = int.tryParse(lead.campaignId!);
          if (intId != null) {
            campaignProgressNotifier.markUpdated(intId);
          }
        }

        // Refresh Interested Leads list
        fetchInterestedLeads();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot open dialer")),
      );
    }
  }



  Future<void> sendEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> convertLead(Lead lead) async {
    await LeadService.updateLeadStatus(lead.id, 'converted');
    fetchInterestedLeads();
  }

  String getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0];
    return parts[0][0] + parts.last[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Interested Leads',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: const BackButton(color: Colors.black),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.tune, color: Colors.black),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Search
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: filterLeads,
                decoration: const InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: 'Search leads by name...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 🏷 Filter Pills
            Row(
              children: [
                _pill('All', selected: true),
                const SizedBox(width: 8),
                _pill('High Interest'),
                const SizedBox(width: 8),
                _pill('Mortgage'),
                const SizedBox(width: 8),
                _pill('Insurance'),
              ],
            ),
            const SizedBox(height: 16),

            // 📋 Leads
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLeads.isEmpty
                  ? const Center(
                child: Text('No interested leads found'),
              )
                  : ListView.builder(
                itemCount: filteredLeads.length,
                itemBuilder: (context, index) {
                  final lead = filteredLeads[index];
                  return _leadCard(lead);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Leads'),
          BottomNavigationBarItem(
              icon: Icon(Icons.campaign), label: 'Campaigns'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Call Stats'),
        ],
      ),
    );
  }

  // 🔹 Filter pill
  Widget _pill(String text, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.black : Colors.white,
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

  // 🔹 Lead Card
  Widget _leadCard(Lead lead) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeadDetailsScreen(
              lead: lead,
              onLeadUpdated: fetchInterestedLeads,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: Text(getInitials(lead.name)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lead.company ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Interested',
                    style: TextStyle(
                        fontSize: 12, color: Colors.green),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => makeCall(lead),
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        sendEmail(lead.email ?? ''),
                    icon: const Icon(Icons.email, size: 16),
                    label: const Text('Email'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LeadDetailsScreen(
                            lead: lead,
                            onLeadUpdated: fetchInterestedLeads,
                          ),
                        ),
                      );
                    },
                    child: const Text('Nurture Lead'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => convertLead(lead),
                    child: const Text('Convert →'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
