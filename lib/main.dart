import 'package:flutter/material.dart';
// import 'package:internship_app/screens/all_leads_overview.dart';
// import 'package:internship_app/screens/call_stat_screen.dart';
// import 'package:internship_app/screens/campaignscreen.dart';
// import 'package:internship_app/screens/contacted_leads_screen.dart';
import 'package:internship_app/screens/create-template.dart';
// import 'package:internship_app/screens/donor_details_scrren.dart';
// import 'package:internship_app/screens/donor_form_screen.dart';
// import 'package:internship_app/screens/edit_profile_screen.dart';
// import 'package:internship_app/screens/fresh_leads_screen.dart';
// import 'package:internship_app/screens/interested_leads.dart';
// import 'package:internship_app/screens/login.dart';
// import 'package:internship_app/screens/message_template_screen.dart';
// import 'package:internship_app/screens/my_donors_screen.dart';
// import 'package:internship_app/screens/prasadam_form_entry.dart';
// import 'package:internship_app/screens/select_whatsapp_message.dart';
// import 'package:internship_app/screens/setting_screen.dart';
import 'screens/dashboard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final Map<String, dynamic> mockUser = {
  'profileImageUrl': '',
  'fullName': 'Maria Shaikh',
  'userName': 'maria123',
  'email': 'maria@example.com',
  'mobile': '+91 9876543210',
  'employeeId': 'EMP001',
  };
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Internship App',
      home: DashboardScreen(),
    );
  }
}
