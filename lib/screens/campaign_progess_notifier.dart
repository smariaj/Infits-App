import 'package:flutter/material.dart';

class CampaignProgressNotifier extends ChangeNotifier {
  int? _updatedCampaignId;

  void markUpdated(int campaignId) {
    _updatedCampaignId = campaignId;
    notifyListeners();
  }

  int? get updatedCampaignId => _updatedCampaignId;
}

final campaignProgressNotifier = CampaignProgressNotifier();
