import 'package:flutter/material.dart';

class AgentDashboardNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

final agentDashboardNotifier = AgentDashboardNotifier();
