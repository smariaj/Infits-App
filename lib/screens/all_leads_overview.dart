import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class Lead {
  final String name;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String timeText;

  Lead({
    required this.name,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.timeText,
  });
}

class AllLeadsScreen extends StatefulWidget {
  const AllLeadsScreen({super.key});

  @override
  State<AllLeadsScreen> createState() => _AllLeadsScreenState();
}

class _AllLeadsScreenState extends State<AllLeadsScreen> {

  final String baseUrl = "http://10.0.2.2:3000/api/message-templates";
  Future<void> openTemplatePicker(
      BuildContext context,
      String leadName,
      String phoneNumber,
      ) async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode != 200) return;

    final List templates = json.decode(response.body);

    showModalBottomSheet(
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
              title: Text(template["name"]),
              subtitle: Text(
                template["message"],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.pop(context);
                openVariableDialog(
                  context,
                  template["id"],
                  phoneNumber,
                  (template["variables"] is String)
                      ? List<String>.from(jsonDecode(template["variables"]))
                      : List<String>.from(template["variables"]),

                );
              },
            );
          },
        );
      },
    );
  }
  void openVariableDialog(
      BuildContext context,
      int templateId,
      String phoneNumber,
      List<String> variables,
      ) {
    final Map<String, TextEditingController> controllers = {
      for (var v in variables) v: TextEditingController()
    };

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Fill message details"),
          content: SingleChildScrollView(
            child: Column(
              children: variables.map((v) {
                return TextField(
                  controller: controllers[v],
                  decoration: InputDecoration(
                    labelText: v.replaceAll("_", " "),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                Future.microtask(() {
                  sendWhatsAppMessage(
                    templateId,
                    phoneNumber,
                    variables,
                    controllers,
                  );
                });
              },
              child: const Text("Open WhatsApp"),
            ),

          ],
        );
      },
    );
  }
  Future<void> sendWhatsAppMessage(
      int templateId,
      String phoneNumber,
      List<String> variables,
      Map<String, TextEditingController> controllers,
      ) async {
    final values = variables.map((v) => controllers[v]!.text).toList();

    print("VALUES: $values");

    final response = await http.post(
      Uri.parse("$baseUrl/send"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "templateId": templateId,
        "phoneNumber": phoneNumber,
        "values": values,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final url = data["whatsappUrl"];

      print("WHATSAPP URL: $url");

      final uri = Uri.parse(url);

      final canLaunch = await canLaunchUrl(uri);
      print("CAN LAUNCH: $canLaunch");

      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print("❌ WhatsApp not available on this device");
      }
    }
  }


  List<Lead> leads = [
    Lead(
        name: 'Sarah Jenkins',
        subtitle: 'Tech Solutions Inc.',
        status: 'Fresh',
        statusColor: Colors.blue,
        timeText: 'Added today'),
    Lead(
        name: 'Michael Ross',
        subtitle: 'Real Estate Inquiry',
        status: 'Interested',
        statusColor: Colors.green,
        timeText: 'Last call: 10am'),
    Lead(
        name: 'Anita Lopez',
        subtitle: 'Event Follow-up',
        status: 'Contacted',
        statusColor: Colors.grey,
        timeText: '2 days ago'),
    Lead(
        name: 'David Chen',
        subtitle: 'Q3 Sales Push',
        status: 'Callback',
        statusColor: Colors.orange,
        timeText: '15m ago'),
    Lead(
        name: 'Emily Watson',
        subtitle: 'Website Lead',
        status: 'Fresh',
        statusColor: Colors.blue,
        timeText: 'Added 1h ago'),
  ];

  String selectedStatusFilter = "All";
  String searchQuery = "";
  List<String> statusFilters = ["All", "Fresh", "Contacted", "Interested"];

  List<Lead> get filteredLeads {
    List<Lead> temp = leads;

    // Filter by status
    if (selectedStatusFilter != "All") {
      temp = temp.where((l) => l.status == selectedStatusFilter).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      temp = temp
          .where((l) =>
      l.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          l.subtitle.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return temp;
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
              child: filteredLeads.isEmpty
                  ? const Center(child: Text("No leads found"))
                  : ListView.builder(
                itemCount: filteredLeads.length,
                itemBuilder: (context, index) {
                  var lead = filteredLeads[index];
                  return LeadCard(
                    name: lead.name,
                    subtitle: lead.subtitle,
                    status: lead.status,
                    statusColor: lead.statusColor,
                    timeText: lead.timeText,
                    onWhatsAppTap: () {
                      openTemplatePicker(context, lead.name, "919999999999");
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
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Leads'),
          BottomNavigationBarItem(
              icon: Icon(Icons.campaign), label: 'Campaigns'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Call Stats'),
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
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          icon: Icon(Icons.search),
          hintText: 'Search by name or number...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _statusFilters() {
    return Row(
      children: statusFilters.map((status) {
        bool isSelected = selectedStatusFilter == status;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedStatusFilter = status;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
        ));
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
  final VoidCallback onWhatsAppTap;

  const LeadCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.timeText,
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
                Text(subtitle,
                    style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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
                    Text(timeText,
                        style:
                        const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble, color: Colors.green),
            onPressed: onWhatsAppTap,
          ),


          IconButton(
            icon: const Icon(Icons.call, color: Colors.blue),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
