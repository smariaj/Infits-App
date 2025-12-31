import 'package:flutter/material.dart';

String username = 'Maria Shaikh'; // fetched from backend
String initials = username.isNotEmpty
    ? username.trim().split(" ").map((e) => e[0]).take(2).join()
    : "";
String designation= 'XYZ';



class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                child: Text(
                  initials, // Initials for now, dynamic later
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(designation,
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // Edit profile action
                },
                icon: const Icon(Icons.edit, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Account Section
          const Text("Account", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _settingsTile(
              icon: Icons.lock, title: "Change Password", onTap: () {}),
          _settingsTile(icon: Icons.privacy_tip, title: "Privacy", onTap: () {}),
          _settingsTile(icon: Icons.settings, title: "Settings", onTap: () {}),
          const SizedBox(height: 16),

          // App Preference Section
          const Text("App Preference",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _settingsTile(
              icon: Icons.notifications, title: "Notifications", onTap: () {}),
          _settingsTile(icon: Icons.call, title: "Call Settings", onTap: () {}),
          _settingsTile(icon: Icons.language, title: "Language & Region", onTap: () {}),
          const SizedBox(height: 16),

          // Support Section
          const Text("Support & About",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _settingsTile(icon: Icons.help_center, title: "Help Center", onTap: () {}),
          _settingsTile(icon: Icons.report_problem, title: "Report an Issue", onTap: () {}),
          const SizedBox(height: 16),

          // Logout Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                _showSignOutDialog(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text("Log Out"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      onTap: onTap,
    );
  }
}

void _showSignOutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                "Are you sure you want to sign out?\nYou will need to log in again.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text("Cancel"),
                  ),

                  // Yes, Sign Out Button
                  ElevatedButton(
                    onPressed: () {
                      // Handle sign out logic here
                      Navigator.of(context).pop(); // Close dialog
                      // Optionally navigate to login screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text("Yes, Sign Out"),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

