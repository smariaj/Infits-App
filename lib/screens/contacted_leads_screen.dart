import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:internship_app/models/lead_model.dart';
import 'package:internship_app/screens/lead_and_activity_details.dart';
import 'package:internship_app/services/lead_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:internship_app/screens/campaign_progess_notifier.dart';

class ContactedLeadsScreen extends StatefulWidget {
  const ContactedLeadsScreen({super.key});

  @override
  State<ContactedLeadsScreen> createState() => _ContactedLeadsScreenState();
}

class _ContactedLeadsScreenState extends State<ContactedLeadsScreen> {
  List<Lead> allLeads = [];
  List<Lead> filteredLeads = [];
  bool isLoading = true;
  int? agentId;
  String selectedTab = 'all';
  String searchQuery = '';
  String? userName;

  @override
  void initState() {
    super.initState();
    loadUserAndLeads();
  }

  Future<void> loadUserAndLeads() async {
    final prefs = await SharedPreferences.getInstance();
    agentId = prefs.getInt('user_id');
    userName = prefs.getString('user_name');
    if (agentId != null) fetchContactedLeads();
  }

  // ✅ Robust normalization to handle backend variations
  String normalizeStatus(String status) {
    final s = status.toLowerCase().trim();

    if (['interested'].any((v) => s.contains(v))) return 'interested';
    if (['callback', 'call back', 'call-back'].any((v) => s.contains(v))) return 'callback';
    if (['no answer', 'no-answer'].any((v) => s.contains(v))) return 'no answer';
    if (['rejected'].any((v) => s.contains(v))) return 'rejected';

    return 'other';
  }

  Future<void> fetchContactedLeads() async {
    setState(() => isLoading = true);

    final leads = await LeadService.getLeadsByAgent(agentId!);

    setState(() {
      // Keep only leads with known statuses
      allLeads = leads.where((l) {
        final normalized = normalizeStatus(l.status);
        return normalized != 'other';
      }).toList();

      applyFilter();
      isLoading = false;
    });
  }

  void applyFilter() {
    List<Lead> tempLeads;

    if (selectedTab == 'all') {
      tempLeads = allLeads;
    } else {
      tempLeads = allLeads
          .where((l) => normalizeStatus(l.status) == selectedTab)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      filteredLeads = tempLeads.where((lead) {
        return lead.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            lead.phone.contains(searchQuery);
      }).toList();
    } else {
      filteredLeads = tempLeads;
    }
  }

  Future<void> archiveLead(int leadId) async {
    await LeadService.updateLeadStatus(leadId, 'archived');
    fetchContactedLeads();
  }

  Future<void> callNow(Lead lead, {String? campaignId}) async {
    final phone = lead.phone;
    if (phone.isEmpty) return;

    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      final launched = await launchUrl(url);
      if (launched) {
        // Get user ID and name from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt("user_id");
        final userName = prefs.getString("user_name");

        if (userId != null && userName != null) {
          await LeadService.logCallActivity(
            leadId: lead.id,
            userId: userId,
            user: userName,  // <-- send user name too
          );
        }

        // Notify campaign screen to refresh
        if (campaignId != null) {
          final intId = int.tryParse(campaignId);
          if (intId != null) {
            campaignProgressNotifier.markUpdated(intId);
          }
        }

        // Refresh leads list
        fetchContactedLeads();
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer')),
        );
      }
    }
  }





  String _getAgentInitials() {
    if (userName != null && userName!.isNotEmpty) {
      final parts = userName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return userName!.substring(0, 1).toUpperCase();
    }
    return 'AG';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Contacted Leads',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: false,
        titleSpacing: 16,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Text(
                _getAgentInitials(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _searchBar(),
            const SizedBox(height: 12),
            _tabs(),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLeads.isEmpty
                  ? const Center(
                child: Text(
                  'No leads found',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: filteredLeads.length,
                itemBuilder: (_, i) => _leadCard(filteredLeads[i]),
              ),
            ),
          ],
        ),
      ),
      /*bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: 1, // Leads tab selected
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Leads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Campaigns',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Call Stats',
          ),
        ],

      ),*/
    );
  }

  // 🔍 Search
  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey),
          hintText: 'Search name or phone number',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            applyFilter();
          });
        },
      ),
    );
  }

  // 🏷 Tabs
  Widget _tabs() {
    final tabs = [
      {'key': 'all', 'label': 'All'},
      {'key': 'interested', 'label': 'Interested'},
      {'key': 'callback', 'label': 'Callback'},
      {'key': 'rejected', 'label': 'Rejected'},
      {'key': 'no answer', 'label': 'No Answer'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final active = selectedTab == tab['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTab = tab['key']!;
                  applyFilter();
                });
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? Colors.blue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:
                  active ? null : Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  tab['label']!,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 📋 Lead Card
  Widget _leadCard(Lead lead) {
    final status = normalizeStatus(lead.status);
    final description = lead.company ?? '';
    Color badgeColor;
    switch (status) {
      case 'interested':
        badgeColor = Colors.green.shade100;
        break;
      case 'callback':
        badgeColor = Colors.orange.shade100;
        break;
      case 'rejected':
        badgeColor = Colors.red.shade100;
        break;
      case 'no answer':
        badgeColor = Colors.blue.shade100;
        break;
      default:
        badgeColor = Colors.grey.shade200;
    }

    Widget actionButtons = Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeadDetailsScreen(
                    lead: lead,
                    onLeadUpdated: fetchContactedLeads,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Update'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => callNow(lead,campaignId: lead.campaignId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Call Now'),
          ),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _getAvatarColor(lead.name),
                radius: 20,
                child: Text(
                  _getInitials(lead.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lead.phone,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  lead.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _getStatusTextColor(status),
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          actionButtons,
        ],
      ),
    );
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'interested':
        return Colors.green.shade800;
      case 'callback':
        return Colors.orange.shade800;
      case 'rejected':
        return Colors.red.shade800;
      case 'no answer':
        return Colors.blue.shade800;
      default:
        return Colors.black;
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
    ];
    final index = name.length % colors.length;
    return colors[index];
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name.substring(0, 1).toUpperCase();
    }
    return '?';
  }
}
