import 'package:flutter/material.dart';
import 'package:internship_app/models/lead_model.dart';
import 'package:internship_app/models/campaign.dart';
import 'package:internship_app/services/lead_service.dart';
import 'package:internship_app/models/campaignrepo.dart';
import 'package:internship_app/screens/contacted_leads_screen.dart';
import 'package:internship_app/screens/fresh_leads_screen.dart';
import 'package:internship_app/screens/interested_leads.dart';
import 'package:internship_app/screens/lead_and_activity_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internship_app/screens/campaign_progess_notifier.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/* ================= WHATSAPP SERVICE ================= */
class WhatsAppService {
  static const String baseUrl = "http://10.169.30.216:3000/api/message-templates";

  static Future<void> openTemplatePicker(
      BuildContext context, String leadName, String phoneNumber) async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode != 200) {
        debugPrint("Failed to fetch templates: ${response.statusCode}");
        _showError(context, "Failed to load message templates");
        return;
      }

      final List templates = json.decode(response.body);

      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) {
          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                title: Text(template["name"] ?? "Unnamed Template"),
                subtitle: Text(
                  template["message"] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.pop(context);
                  Future.microtask(() {
                    openVariableDialog(
                      context,
                      template["id"],
                      phoneNumber,
                      (template["variables"] is String)
                          ? List<String>.from(jsonDecode(template["variables"]))
                          : List<String>.from(template["variables"] ?? []),
                    );
                  });
                },
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint("Error loading templates: $e");
      _showError(context, "Error: $e");
    }
  }

  static void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static void openVariableDialog(BuildContext context, int templateId,
      String phoneNumber, List<String> variables) {
    showDialog(
      context: context,
      builder: (context) => _VariableDialog(
        templateId: templateId,
        phoneNumber: phoneNumber,
        variables: variables,
      ),
    );
  }

  static Future<void> sendWhatsAppMessage(
      int templateId, String phoneNumber, List<String> values) async {
    try {
      debugPrint("📱 Sending WhatsApp message to: $phoneNumber");

      // Format phone number PROPERLY for WhatsApp
      final formattedPhone = _formatPhoneNumberForWhatsApp(phoneNumber);
      debugPrint("📱 Formatted phone for WhatsApp: $formattedPhone");

      // First try using your backend API
      final response = await http.post(
        Uri.parse("$baseUrl/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "templateId": templateId,
          "phoneNumber": formattedPhone,
          "values": values,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final url = data["whatsappUrl"];
        debugPrint("📱 Backend generated URL: $url");

        await _launchWhatsAppUrl(Uri.parse(url), formattedPhone, values);
      } else {
        debugPrint("❌ Backend failed, generating URL locally");
        // Fallback: generate URL locally
        await _generateAndLaunchWhatsAppUrl(formattedPhone, values);
      }
    } catch (e) {
      debugPrint("❌ Error sending WhatsApp: $e");
      rethrow;
    }
  }

  static String _formatPhoneNumberForWhatsApp(String phoneNumber) {
    // Remove all non-digit characters except +
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

    // If starts with 0, remove it (common for local numbers)
    if (cleanNumber.startsWith('0')) {
      cleanNumber = cleanNumber.substring(1);
    }

    // If doesn't start with +, add country code (assuming India +91)
    if (!cleanNumber.startsWith('+')) {
      // Check if already has country code
      if (cleanNumber.length == 10) {
        cleanNumber = '+91$cleanNumber'; // India country code
      } else if (cleanNumber.length == 12 && cleanNumber.startsWith('91')) {
        cleanNumber = '+$cleanNumber';
      }
    }

    return cleanNumber;
  }

  static Future<void> _launchWhatsAppUrl(
      Uri uri, String phoneNumber, List<String> values) async {
    debugPrint("🔄 Launching URL: $uri");

    if (await canLaunchUrl(uri)) {
      debugPrint("✅ Can launch URL, opening WhatsApp...");
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("❌ Cannot launch URL, trying alternative formats...");
      await _tryAlternativeWhatsAppUrls(phoneNumber, values);
    }
  }

  static Future<void> _tryAlternativeWhatsAppUrls(
      String phoneNumber, List<String> values) async {
    // Join values into message
    final message = values.join(', ');
    final encodedMessage = Uri.encodeComponent(message);

    debugPrint("💬 Message: $message");
    debugPrint("🔢 Phone: $phoneNumber");

    // Format 1: wa.me (most reliable)
    final url1 = "https://wa.me/$phoneNumber?text=$encodedMessage";
    debugPrint("🔄 Trying URL format 1: $url1");

    final uri1 = Uri.parse(url1);
    if (await canLaunchUrl(uri1)) {
      debugPrint("✅ Format 1 works, launching...");
      await launchUrl(uri1, mode: LaunchMode.externalApplication);
      return;
    }

    // Format 2: api.whatsapp.com
    final url2 = "https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage";
    debugPrint("🔄 Trying URL format 2: $url2");

    final uri2 = Uri.parse(url2);
    if (await canLaunchUrl(uri2)) {
      debugPrint("✅ Format 2 works, launching...");
      await launchUrl(uri2, mode: LaunchMode.externalApplication);
      return;
    }

    // Format 3: Without https://
    final url3 = "whatsapp://send?phone=$phoneNumber&text=$encodedMessage";
    debugPrint("🔄 Trying URL format 3: $url3");

    final uri3 = Uri.parse(url3);
    if (await canLaunchUrl(uri3)) {
      debugPrint("✅ Format 3 works, launching...");
      await launchUrl(uri3, mode: LaunchMode.externalApplication);
      return;
    }

    debugPrint("❌ All WhatsApp URL formats failed");

    // Show user instructions
    _showManualInstructions(phoneNumber, message);
  }

  static Future<void> _generateAndLaunchWhatsAppUrl(
      String phoneNumber, List<String> values) async {
    final message = values.join(', ');
    final encodedMessage = Uri.encodeComponent(message);

    // Try direct WhatsApp URL first
    final url = "https://wa.me/$phoneNumber?text=$encodedMessage";

    await _launchWhatsAppUrl(Uri.parse(url), phoneNumber, values);
  }

  static void _showManualInstructions(String phoneNumber, String message) {
    // This would be called from a context-aware method
    debugPrint("""
    📱 MANUAL WHATSAPP INSTRUCTIONS:
    Phone: $phoneNumber
    Message: $message
    
    To send manually:
    1. Open WhatsApp
    2. Start new chat
    3. Enter: $phoneNumber
    4. Paste: $message
    5. Send
    """);
  }
}

// Separate StatefulWidget for the dialog
class _VariableDialog extends StatefulWidget {
  final int templateId;
  final String phoneNumber;
  final List<String> variables;

  const _VariableDialog({
    required this.templateId,
    required this.phoneNumber,
    required this.variables,
  });

  @override
  State<_VariableDialog> createState() => __VariableDialogState();
}

class __VariableDialogState extends State<_VariableDialog> {
  late final Map<String, TextEditingController> _controllers;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (var variable in widget.variables) {
      _controllers[variable] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Fill message details"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.variables.map((v) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _controllers[v]!,
                decoration: InputDecoration(
                  labelText: v.replaceAll("_", " "),
                  border: const OutlineInputBorder(),
                  hintText: "Enter ${v.replaceAll('_', ' ')}",
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendWhatsAppMessage,
          child: _isSending
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text("Open WhatsApp"),
        ),
      ],
    );
  }

  Future<void> _sendWhatsAppMessage() async {
    if (!mounted) return;

    setState(() => _isSending = true);

    try {
      // Collect values
      final values = <String>[];
      for (var variable in widget.variables) {
        values.add(_controllers[variable]!.text);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }

      await WhatsAppService.sendWhatsAppMessage(
        widget.templateId,
        widget.phoneNumber,
        values,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to open WhatsApp: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint("Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}
/* ================= ALL LEADS SCREEN ================= */
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
  Campaign? selectedCampaign;
  List<Campaign> campaigns = [];

  final List<String> statusFilters = [
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
    final prefs = await SharedPreferences.getInstance();
    loggedInUserId = prefs.getInt("user_id");

    if (loggedInUserId != null) {
      await loadCampaigns();
      await loadLeads();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadCampaigns() async {
    try {
      final data =
      await CampaignRepository.fetchCampaignsForAgent(loggedInUserId.toString());
      setState(() => campaigns = data);
    } catch (_) {
      debugPrint("Failed to load campaigns");
    }
  }

  Future<void> loadLeads({String? campaignId}) async {
    setState(() => isLoading = true);
    try {
      List<Lead> data;
      if (campaignId != null && campaignId.isNotEmpty) {
        data = await LeadService.getLeadsByAgentAndCampaign(
          agentId: loggedInUserId!,
          campaignId: campaignId,
        );
      } else {
        data = await LeadService.getLeadsByAgent(loggedInUserId!);
      }
      setState(() {
        leads = data;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _refreshLeads() async {
    await loadLeads(campaignId: selectedCampaign?.id.toString());
  }

  List<Lead> get filteredLeads {
    List<Lead> temp = leads;

    if (selectedStatusFilter != "All") {
      temp = temp.where((l) => l.status == selectedStatusFilter).toList();
    }

    if (searchQuery.isNotEmpty) {
      temp = temp
          .where((l) =>
      l.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (l.company ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
          l.phone.contains(searchQuery))
          .toList();
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

  Future<void> makeCall(String phone, int leadId, {String? campaignId}) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString("user_name") ?? "Unknown";

    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      final launched = await launchUrl(uri);
      if (launched) {
        await LeadService.logCallActivity(
          leadId: leadId,
          userName: userName,
        );

        // Notify campaign screen that this campaign should refresh
        if (campaignId != null) {
          final intId = int.tryParse(campaignId);
          if (intId != null) {
            campaignProgressNotifier.markUpdated(intId);
          }
        }
        _refreshLeads();
      }
    }
  }


  void openWhatsAppChat(Lead lead) async {
    await WhatsAppService.openTemplatePicker(context, lead.name, lead.phone);
  }

  void openLeadDetails(Lead lead) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeadDetailsScreen(
          lead: lead,
          onLeadUpdated: _refreshLeads,
        ),
      ),
    );

    // Refresh leads when coming back from details screen
    await _refreshLeads();
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _refreshLeads,
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
                  : RefreshIndicator(
                onRefresh: _refreshLeads,
                child: ListView.builder(
                  itemCount: filteredLeads.length,
                  itemBuilder: (_, index) {
                    final lead = filteredLeads[index];
                    return GestureDetector(
                      onTap: () => openLeadDetails(lead),
                      child: LeadCard(
                        name: lead.name,
                        subtitle: lead.company ?? 'No company',
                        status: lead.status,
                        statusColor: statusColor(lead.status),
                        timeText: lead.lastActivity,
                        onCallPressed: () => makeCall(lead.phone, lead.id,campaignId: lead.campaignId,),
                        onWhatsAppTap: () => openWhatsAppChat(lead),
                      ),
                    );
                  },
                ),
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
          final isSelected = selectedStatusFilter == status;
          return GestureDetector(
            onTap: () async {
              setState(() => selectedStatusFilter = status);
              if (status == 'New Lead') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FreshLeadsScreen()));
              } else if (status == 'Interested') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const InterestedLeadsScreen()));
              } else if (status == 'Call Back') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ContactedLeadsScreen()));
              }
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
          _campaignDropdown(),
          _dropdown('Date Added'),
          _dropdown('Priority'),
          _dropdown('Source'),
        ],
      ),
    );
  }

  Widget _campaignDropdown() {
    return GestureDetector(
      onTap: () async {
        final selected = await showModalBottomSheet<Campaign>(
          context: context,
          builder: (_) => ListView(
            children: [
              ListTile(
                title: const Text("All Campaigns"),
                onTap: () => Navigator.pop(_, null),
              ),
              ...campaigns.map(
                    (c) => ListTile(
                  title: Text(c.title),
                  onTap: () => Navigator.pop(_, c),
                ),
              ),
            ],
          ),
        );

        setState(() {
          selectedCampaign = selected;
        });

        await loadLeads(campaignId: selected?.id.toString());
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(selectedCampaign?.title ?? 'Campaign',
                style: const TextStyle(fontSize: 12)),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
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

/* ================= LEAD CARD ================= */
class LeadCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String timeText;
  final VoidCallback onCallPressed;
  final VoidCallback onWhatsAppTap;

  const LeadCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.timeText,
    required this.onCallPressed,
    required this.onWhatsAppTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    // Wrap timeText in Expanded + TextOverflow.ellipsis
                    Expanded(
                      child: Text(
                        timeText,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),
          IconButton(
            onPressed: onWhatsAppTap,
            icon: const Icon(Icons.chat_bubble, color: Colors.green, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          IconButton(
            onPressed: onCallPressed,
            icon: const Icon(Icons.call, color: Colors.blue, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),

        ],
      ),
    );
  }
}