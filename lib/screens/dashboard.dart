import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';


// Screens placeholders
import 'all_leads_overview.dart';
import 'call_stat_screen.dart';
import 'message_template_screen.dart';
import 'donor_form_screen.dart';
import 'prasadam_form_entry.dart';
import 'campaignscreen.dart';
import 'profileScreen.dart';
import 'setting_screen.dart';



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedDrawerIndex = 0;
  int selectedBottomNavIndex = 0;
  bool acceptingCalls = true;
  int highPriorityLeads = 8;
  int todayHighPriority = 2;
  int freshLeads = 42;
  int contactedLeads = 15;
  List<Map<String, String>> recentActivities = [
    {'name': 'John Doe', 'status': 'No answer • Added to callback list', 'time': '2m ago'},
    {'name': 'Sarah Smith', 'status': 'Callback scheduled • Pricing Inquiry', 'time': '2:00 PM'},
    {'name': 'Michael Key', 'status': 'Deal Closed • Contract sent', 'time': '1h ago'},
  ];

  // List of screens for bottom nav
  final List<Widget> bottomNavScreens = [
    const DashboardScreen(),
    const AllLeadsScreen(),
    const CampaignsScreen(),
    CallStatsScreen(),
  ];

  // List of drawer screens
  final Map<int, Widget> drawerScreens = {
    0: const AllLeadsScreen(),
    1: const CampaignsScreen(),
    2: const MessageTemplateScreen(),
    3: const RecordDefinitionScreen(),
    4: const ParsadamFormScreen(telecallerName: 'xyz'),
    5: CallStatsScreen(),
    6: const SettingsScreen(), // Sign out or placeholder
  };

  String username="User";
  bool accepting_calls=true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? "User";
    });
  }


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
        actions: const [
          Icon(Icons.notifications, color: Colors.black),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // High Priority Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4E91FC), Color(0xFF00C6FF)],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('HIGH PRIORITY', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text('Interested Leads',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text('$highPriorityLeads +$todayHighPriority today',
                            style: const TextStyle(color: Colors.yellow, fontSize: 20)),
                      ],
                    ),
                  ),
                  const Icon(Icons.star, color: Colors.yellow, size: 75),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Two small cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text('$freshLeads',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Fresh Leads', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text('$contactedLeads',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Contacted', textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        const Text('Pending', style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Quick actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                quickAction(Icons.phone, 'Start Dialing', onTap: _startDialing),
                quickAction(Icons.person_add, 'Add Lead', onTap: () => _navigate(context, const AllLeadsScreen())),
                quickAction(Icons.description, 'View Script', onTap: () => _navigate(context, const MessageTemplateScreen())),
                quickAction(Icons.calendar_today, 'Tasks', onTap: () => _navigate(context, const CampaignsScreen())),
              ],
            ),

            const SizedBox(height: 20),
            const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Recent activity list
            Column(
              children: recentActivities
                  .map((item) => recentActivity(item['name']!, item['status']!, item['time']!))
                  .toList(),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedBottomNavIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            selectedBottomNavIndex = index;
          });
          _navigate(context, bottomNavScreens[index]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Leads'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Campaigns'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Call Stats'),
        ],
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
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Text(
                            _getInitials(userName),
                            style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text('View Profile',
                                style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          acceptingCalls ? 'Accepting Calls' : 'Not Accepting Calls',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Switch(
                          value: acceptingCalls,
                          activeColor: Colors.white,
                          activeTrackColor: Colors.white54,
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.white30,
                          onChanged: (value) {
                            setState(() {
                              acceptingCalls = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Fixed drawer items
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('All Leads'),
                onTap: () => _navigate(context, const AllLeadsScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.campaign),
                title: const Text('Campaigns'),
                onTap: () => _navigate(context, const CampaignsScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Message Templates'),
                onTap: () => _navigate(context, const MessageTemplateScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Record Definition'),
                onTap: () => _navigate(context, const RecordDefinitionScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.food_bank),
                title: const Text('Prasadam Form'),
                onTap: () => _navigate(context, const ParsadamFormScreen(telecallerName: 'xyz')),
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Call Stats'),
                onTap: () => _navigate(context, CallStatsScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () => _navigate(context, const SettingsScreen()),
              ),
            ],
          ),
        )

    );
  }

  // Quick action button
  Widget quickAction(IconData icon, String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(icon, color: Colors.blue, size: 28)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // Recent activity row
  Widget recentActivity(String name, String status, String time) {
    return ListTile(
      leading: CircleAvatar(child: Text(name[0])),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(status),
      trailing: Text(time),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _startDialing() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '1234567890');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot launch phone app')));
    }
  }

  String userName = "Maria Shaikh"; // this can come from your login/user data

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    String initials = '';
    for (var n in names) {
      if (n.isNotEmpty) initials += n[0].toUpperCase();
    }
    return initials;
  }

}
