import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Screens
import 'all_leads_overview.dart';
import 'call_stat_screen.dart';
import 'message_template_screen.dart';
import 'donor_form_screen.dart';
import 'prasadam_form_entry.dart';
import 'campaignscreen.dart';
import 'setting_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String baseUrl = "http://10.0.2.2:3000";


  int selectedBottomNavIndex = 0;
  bool acceptingCalls = true;

  int highPriorityLeads = 0;
  int todayHighPriority = 0;
  int freshLeads = 0;
  int contactedLeads = 0;

  String userName = "User";
  String profileImage = "";
  String agentId = "101";

  List<Map<String, String>> recentActivities = [];
  final List<Map<String, String>> fallbackRecentActivities = [
    {
      'name': 'John Doe',
      'status': 'No answer • Added to callback list',
      'time': '2m ago'
    },
    {
      'name': 'Sarah Smith',
      'status': 'Callback scheduled • Pricing Inquiry',
      'time': '2:00 PM'
    },
    {
      'name': 'Michael Key',
      'status': 'Deal Closed • Contract sent',
      'time': '1h ago'
    },
  ];

  @override
  void initState() {
    super.initState();
    print("DASHBOARD INIT STATE CALLED");
    _loadUserData().then((_) {
      _loadDashboardData();
      _loadRecentActivity();
      _loadCallStatus();
    });
  }

  /* ===============================
     LOAD USER DATA
  =============================== */
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? "User";
      profileImage = prefs.getString("profile_image") ?? "";
      // agentId = prefs.getInt("user_id")?.toString() ?? "0";
      agentId = "101";

    });
  }

  /* ===============================
     DASHBOARD SUMMARY
  =============================== */
  Future<void> _loadDashboardData() async {
    if (agentId == "0") return;
    print("===============================.");
    print("Calling dashboard summary API...");
    print("$baseUrl/dashboard/summary/$agentId");

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/dashboard/summary/$agentId"),
      );

      print("Dashboard status: ${response.statusCode}");
      print("Dashboard body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          highPriorityLeads = data["highPriorityLeads"];
          todayHighPriority = data["todayHighPriority"];
          freshLeads = data["freshLeads"];
          contactedLeads = data["contactedLeads"];
        });
      }
    } catch (e) {
      print("Dashboard API ERROR: $e");
    }
  }


  /* ===============================
     RECENT ACTIVITY
  =============================== */
  Future<void> _loadRecentActivity() async {
    if (agentId == "0") {
      setState(() {
        recentActivities = fallbackRecentActivities;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/dashboard/recent-activity/$agentId"),
      );

      if (response.statusCode == 200) {
        final List list = json.decode(response.body);

        if (list.isEmpty) {
          setState(() {
            recentActivities = fallbackRecentActivities;
          });
        } else {
          setState(() {
            recentActivities = list
                .map<Map<String, String>>((e) => {
              "name": e["name"].toString(),
              "status": e["status"].toString(),
              "time": e["time"].toString(),
            })
                .toList();
          });
        }
      } else {
        setState(() {
          recentActivities = fallbackRecentActivities;
        });
      }
    } catch (e) {
      setState(() {
        recentActivities = fallbackRecentActivities;
      });
    }
  }


  /* ===============================
     CALL STATUS
  =============================== */
  Future<void> _loadCallStatus() async {
    if (agentId == "0") return;

    final response = await http.get(
      Uri.parse("$baseUrl/agents/$agentId/call-status"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        acceptingCalls = data["acceptingCalls"];
      });
    }
  }

  Future<void> _updateCallStatus(bool value) async {
    await http.put(
      Uri.parse("$baseUrl/agents/$agentId/call-status"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"acceptingCalls": value}),
    );
  }

  /* ===============================
     PROFILE AVATAR
  =============================== */
  Widget _buildProfileAvatar() {
    if (profileImage.isEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white,
        child: Text(
          _getInitials(userName),
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white,
      backgroundImage:
      NetworkImage("$baseUrl/uploads/$profileImage"),
      onBackgroundImageError: (_, __) {
        setState(() {
          profileImage = "";
        });
      },
    );
  }

  /* ===============================
     BUILD UI
  =============================== */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Dashboard', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildProfileAvatar(),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const Text('View Profile',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        acceptingCalls
                            ? 'Accepting Calls'
                            : 'Not Accepting Calls',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Switch(
                        value: acceptingCalls,
                        activeColor: Colors.white,
                        onChanged: (value) {
                          setState(() => acceptingCalls = value);
                          _updateCallStatus(value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            _drawerItem(Icons.person, 'All Leads', const AllLeadsScreen()),
            _drawerItem(Icons.campaign, 'Campaigns',
                CampaignsScreen(agentId: agentId)),
            _drawerItem(Icons.message, 'Message Templates',
                const MessageTemplateScreen()),
            _drawerItem(Icons.description, 'Record Definition',
                const RecordDefinitionScreen()),
            _drawerItem(Icons.food_bank, 'Prasadam Form',
                const ParsadamFormScreen(telecallerName: 'xyz')),
            _drawerItem(Icons.bar_chart, 'Call Stats',
                const CallStatsScreen()),
            _drawerItem(Icons.settings, 'Settings',
                const SettingsScreen()),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _highPriorityCard(),
            const SizedBox(height: 16),
            _statsRow(),
            const SizedBox(height: 20),
            const Text('Quick Actions',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _quickActions(),
            const SizedBox(height: 20),
            const Text('Recent Activity',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Column(
              children: recentActivities.map(_recentActivity).toList(),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedBottomNavIndex,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          setState(() => selectedBottomNavIndex = index);
          if (index == 0) return;
          if (index == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AllLeadsScreen()));
          }
          if (index == 2) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        CampaignsScreen(agentId: agentId)));
          }
          if (index == 3) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CallStatsScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Leads'),
          BottomNavigationBarItem(
              icon: Icon(Icons.campaign), label: 'Campaigns'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Call Stats'),
        ],
      ),
    );
  }

  /* ===============================
     HELPERS
  =============================== */
  ListTile _drawerItem(IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      ),
    );
  }

  Widget _highPriorityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4E91FC), Color(0xFF00C6FF)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HIGH PRIORITY',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  const Text('Interested Leads',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '$highPriorityLeads +$todayHighPriority today',
                    style: const TextStyle(
                        color: Colors.yellow, fontSize: 18),
                  ),
                ]),
          ),
          const Icon(Icons.star,
              color: Colors.yellow, size: 70),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _smallCard(freshLeads, 'Fresh Leads'),
        const SizedBox(width: 12),
        _smallCard(contactedLeads, 'Contacted'),
      ],
    );
  }

  Widget _smallCard(int value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text('$value',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(label),
        ]),
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _quickAction(Icons.phone, 'Start Dialing', _startDialing),
        _quickAction(Icons.person_add, 'Add Lead', () {}),
        _quickAction(Icons.description, 'View Script', () {}),
        _quickAction(Icons.calendar_today, 'Tasks', () {}),
      ],
    );
  }

  Widget _quickAction(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(icon, color: Colors.blue)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }

  Widget _recentActivity(Map<String, String> item) {
    return ListTile(
      leading: CircleAvatar(child: Text(item['name']![0])),
      title: Text(item['name']!,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(item['status']!),
      trailing: Text(item['time']!),
    );
  }

  void _startDialing() async {
    final Uri phoneUri =
    Uri(scheme: 'tel', path: '1234567890');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0].toUpperCase())
        .join();
  }
}
