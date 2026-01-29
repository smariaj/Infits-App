import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isLoading = true;
  String userName = "";
  String userProfileImage = "";
  int? userId;
  static const String baseUrl = "http://10.120.217.15:3000";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString("user_name") ?? "User";
      userProfileImage = prefs.getString("profile_image") ?? "";
      userId = prefs.getInt("user_id");
      isLoading = false;
    });
  }

  Future<void> _refreshUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final updatedName = prefs.getString("user_name") ?? "User";
    final updatedImage = prefs.getString("profile_image") ?? "";

    setState(() {
      userName = updatedName;
      userProfileImage = updatedImage;
    });
  }

  String get initials {
    if (userName.isEmpty || userName == "User") return '';

    final cleanedName = userName.trim();
    if (cleanedName.isEmpty) return '';

    final parts = cleanedName.split(' ').where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get _hasValidProfileImage {
    return userProfileImage.isNotEmpty &&
        userProfileImage != "updated" &&
        !userProfileImage.contains("null");
  }

  String? get _profileImageUrl {
    if (!_hasValidProfileImage) return null;
    return "$baseUrl/uploads/$userProfileImage";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PROFILE HEADER - OG Style with your edit functionality
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blueAccent,
                    backgroundImage: _hasValidProfileImage
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: !_hasValidProfileImage
                        ? Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                        : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(
                              userData: {
                                "id": userId?.toString() ?? "",
                                "fullName": userName,
                                "username": userName,
                                "email": "",
                                "mobile": "",
                                "employeeId": userId?.toString() ?? "",
                                "profileImage": _hasValidProfileImage
                                    ? _profileImageUrl
                                    : null,
                              },
                            ),
                          ),
                        );

                        if (updated == true) {
                          await _refreshUserData();
                        }
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Agent", // Default role
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Account Section - OG Style
          const Text("Account", style: TextStyle(fontWeight: FontWeight.bold)),
          _tile(Icons.lock, "Change Password"),
          _tile(Icons.privacy_tip, "Privacy"),
          _tile(Icons.settings, "Settings"),

          const SizedBox(height: 16),

          // App Preference Section - OG Style
          const Text("App Preference",
              style: TextStyle(fontWeight: FontWeight.bold)),
          _tile(Icons.notifications, "Notifications"),
          _tile(Icons.call, "Call Settings"),
          _tile(Icons.language, "Language & Region"),

          const SizedBox(height: 16),

          // Support & About Section - OG Style
          const Text("Support & About",
              style: TextStyle(fontWeight: FontWeight.bold)),
          _tile(Icons.help_center, "Help Center"),
          _tile(Icons.report_problem, "Report an Issue"),

          const SizedBox(height: 24),

          // Logout Button - OG Style
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Log Out"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showSignOutDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pop(context);
              // Navigate to login screen
              Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                      (route) => false
              );
            },
            child: const Text("Yes, Sign Out"),
          ),
        ],
      ),
    );
  }
}