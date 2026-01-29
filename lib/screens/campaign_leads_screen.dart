import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/lead_model.dart';
import '../services/lead_service.dart';
import '../services/whatsapp_service.dart'; // added for WhatsApp
import 'lead_and_activity_details.dart';

class CampaignLeadsScreen extends StatefulWidget {
  final int agentId;
  final String campaignId;
  final String campaignTitle;

  const CampaignLeadsScreen({
    super.key,
    required this.agentId,
    required this.campaignId,
    required this.campaignTitle,
  });

  @override
  State<CampaignLeadsScreen> createState() => _CampaignLeadsScreenState();
}

class _CampaignLeadsScreenState extends State<CampaignLeadsScreen> {
  List<Lead> leads = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    setState(() => isLoading = true);
    try {
      final data = await LeadService.getLeadsByAgentAndCampaign(
        agentId: widget.agentId,
        campaignId: widget.campaignId,
      );
      setState(() => leads = data);
    } catch (_) {
      // silent fail, show empty state
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Lead> get filteredLeads {
    if (searchQuery.isEmpty) return leads;
    return leads.where((l) {
      return l.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          l.phone.contains(searchQuery) ||
          (l.company ?? '').toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _makeCall(String phone, int leadId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");        // Agent ID
    final userName = prefs.getString("user_name"); // Agent name

    if (userId == null || userName == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      final launched = await launchUrl(uri);
      if (launched) {
        // Log the call in backend using user ID AND name
        await LeadService.logCallActivity(
          leadId: leadId,
          userId: userId,
          user: userName,
        );

        // Refresh leads so the latest activity is reflected
        _loadLeads();
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot launch phone dialer')),
        );
      }
    }
  }



  void _openLeadDetails(Lead lead) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeadDetailsScreen(
          lead: lead,
          onLeadUpdated: _loadLeads,
        ),
      ),
    );

    _loadLeads();
  }

  Color _statusColor(String status) {
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
        title: Text(widget.campaignTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeads,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔍 Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: 'Search leads...',
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLeads.isEmpty
                  ? const Center(child: Text("No leads in this campaign"))
                  : RefreshIndicator(
                onRefresh: _loadLeads,
                child: ListView.builder(
                  itemCount: filteredLeads.length,
                  itemBuilder: (_, index) {
                    final lead = filteredLeads[index];

                    return GestureDetector(
                      onTap: () => _openLeadDetails(lead),
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
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lead.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lead.company ?? 'No company',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _statusColor(
                                              lead.status)
                                              .withOpacity(0.15),
                                          borderRadius:
                                          BorderRadius.circular(
                                              12),
                                        ),
                                        child: Text(
                                          lead.status,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _statusColor(
                                                lead.status),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        lead.lastActivity,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.call,
                                      color: Colors.blue, size: 20),
                                  onPressed: () => _makeCall(
                                    lead.phone,
                                    lead.id,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble,
                                      color: Colors.green, size: 20),
                                  onPressed: () =>
                                      WhatsAppService.openTemplatePicker(
                                          context, lead.name, lead.phone),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
