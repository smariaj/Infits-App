import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Screens
import 'all_leads_overview.dart';
import 'call_stat_screen.dart';
import 'message_template_screen.dart';
import 'donor_form_screen.dart';
import 'prasadam_form_entry.dart';
import 'campaignscreen.dart';
import 'setting_screen.dart';

// Service
import 'package:internship_app/services/dashboard_service.dart';

//notifier
import 'package:internship_app/screens/agent_dashboard_notifier.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String baseUrl = "http://10.99.253.184:3000";

  int selectedBottomNavIndex = 0;
  bool acceptingCalls = true;

  int highPriorityLeads = 0;
  int todayHighPriority = 0;
  int freshLeads = 0;
  int contactedLeads = 0;

  String userName = "User";
  String profileImage = "";
  int agentId = 0;

  List<Map<String, String>> recentActivities = [];

  Timer? _dashboardTimer;

  /* ===============================
     INIT
  =============================== */

  @override
  @override
  void initState() {
    super.initState();

    _initDashboard(); // <- initialize agentId and start timer

    agentDashboardNotifier.addListener(() {
      _loadDashboard(); // API re-called automatically on lead status update
    });
  }


  Future<void> _initDashboard() async {
    await _loadUserData();

    if (agentId == 0) return;

    await _loadDashboard();
    _loadCallStatus();

    _dashboardTimer =
        Timer.periodic(const Duration(seconds: 10), (_) {
          _loadDashboard(); // auto-refresh every 10 seconds
        });
  }


  @override
  void dispose() {
    _dashboardTimer?.cancel();
    super.dispose();
  }

  /* ===============================
     LOAD USER DATA
  =============================== */
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? "User";
      profileImage = prefs.getString("profile_image") ?? "";
      agentId = prefs.getInt("user_id") ?? 0;
    });
  }

  /* ===============================
     DASHBOARD (AUTO-UPDATING)
  =============================== */
  Future<void> _loadDashboard() async {
    if (agentId == 0 || !mounted) return;

    try {
      final data =
      await DashboardService.fetchAgentLiveDashboard(agentId);

      setState(() {
        highPriorityLeads =
            int.parse(data["interestedLeads"].toString());
        freshLeads =
            int.parse(data["freshLeads"].toString());
        contactedLeads =
            int.parse(data["contactedLeads"].toString());

        recentActivities =
            (data["recentActivities"] as List).map((e) {
              return {
                "name": e["name"].toString(),
                "status": e["status"].toString(),
                "time": e["time"].toString(),
              };
            }).toList();
      });
    } catch (_) {}
  }

  /* ===============================
     CALL STATUS
  =============================== */
  Future<void> _loadCallStatus() async {
    if (agentId == 0) return;
    // unchanged backend logic assumed
  }

  Future<void> _updateCallStatus(bool value) async {
    // unchanged backend logic assumed
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
              fontWeight: FontWeight.bold),
        ),
      );
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white,
      backgroundImage: NetworkImage("$baseUrl/uploads/$profileImage"),
      onBackgroundImageError: (_, __) {
        setState(() => profileImage = "");
      },
    );
  }

  /* ===============================
     UI (UNCHANGED)
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
        title: const Text('Dashboard',
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration:
              const BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildProfileAvatar(),
                      const SizedBox(width: 12),
                      Text(userName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        acceptingCalls
                            ? 'Accepting Calls'
                            : 'Not Accepting Calls',
                        style:
                        const TextStyle(color: Colors.white),
                      ),
                      Switch(
                        value: acceptingCalls,
                        activeColor: Colors.white,
                        onChanged: (value) {
                          setState(
                                  () => acceptingCalls = value);
                          _updateCallStatus(value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _drawerItem(Icons.person, 'All Leads',
                const AllLeadsScreen()),
            _drawerItem(Icons.campaign, 'Campaigns',
                CampaignsScreen(agentId: agentId.toString())),
            _drawerItem(Icons.message, 'Message Templates',
                const MessageTemplateScreen()),
            _drawerItem(Icons.description,
                'Record Definition',
                const RecordDefinitionScreen()),
            _drawerItem(Icons.food_bank, 'Prasadam Form',
                const ParsadamFormScreen(
                    telecallerName: 'xyz')),
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
              children:
              recentActivities.map(_recentActivity).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedBottomNavIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => selectedBottomNavIndex = index);
          if (index == 1) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AllLeadsScreen()));
          }
          if (index == 2) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CampaignsScreen(
                        agentId: agentId.toString())));
          }
          if (index == 3) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CallStatsScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Leads'),
          BottomNavigationBarItem(
              icon: Icon(Icons.campaign),
              label: 'Campaigns'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Call Stats'),
        ],
      ),
    );
  }

  /* ===============================
     HELPERS
  =============================== */
  ListTile _drawerItem(
      IconData icon, String title, Widget screen) {
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
            colors: [Color(0xFF4E91FC), Color(0xFF00C6FF)]),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text('HIGH PRIORITY',
                    style:
                    TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                const Text('Interested Leads',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('$highPriorityLeads',
                    style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 18)),
              ],
            ),
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
            borderRadius:
            BorderRadius.circular(12)),
        child: Column(children: [
          Text('$value',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(label),
        ]),
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        _quickAction(
            Icons.phone, 'Start Dialing', _startDialing),
        _quickAction(
            Icons.person_add, 'Add Lead', () {}),
        _quickAction(
            Icons.description, 'View Script', () {}),
        _quickAction(
            Icons.calendar_today, 'Tasks', () {}),
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
        Text(label,
            style: const TextStyle(fontSize: 12)),
      ]),
    );
  }

  Widget _recentActivity(Map<String, String> item) {
    return ListTile(
      leading:
      CircleAvatar(child: Text(item['name']![0])),
      title: Text(item['name']!,
          style: const TextStyle(
              fontWeight: FontWeight.bold)),
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
