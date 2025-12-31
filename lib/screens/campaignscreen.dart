import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../models/campaignrepo.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  late List<Campaign> allCampaigns;
  List<Campaign> visibleCampaigns = [];

  String selectedFilter = "Active";

  @override
  void initState() {
    super.initState();
    allCampaigns = CampaignRepository.getCampaigns();
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      if (selectedFilter == "All") {
        visibleCampaigns = allCampaigns;
      } else if (selectedFilter == "Inactive") {
        visibleCampaigns =
            allCampaigns.where((c) => c.status == "Paused").toList();
      } else {
        visibleCampaigns =
            allCampaigns.where((c) => c.status == selectedFilter).toList();
      }
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Active":
        return Colors.green;
      case "Paused":
        return Colors.orange;
      case "Completed":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Campaigns"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Column(
        children: [
          /// 🔍 Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search campaigns...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// 🔘 Filters (scrollable – no overflow)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ["Active", "Inactive", "Completed", "All"].map((filter) {
                final isSelected = selectedFilter == filter;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) {
                      selectedFilter = filter;
                      _applyFilter();
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          /// 📋 Campaign List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visibleCampaigns.length,
              itemBuilder: (context, index) {
                final campaign = visibleCampaigns[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Title + Status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                campaign.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(campaign.status)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                campaign.status,
                                style: TextStyle(
                                  color: _statusColor(campaign.status),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Audience: ${campaign.audience}",
                          style:
                          TextStyle(color: Colors.grey.shade600),
                        ),

                        const SizedBox(height: 12),

                        /// Progress
                        LinearProgressIndicator(
                          value: campaign.progress,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(6),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                "${campaign.called}/${campaign.target} Called"),
                            Text(
                              "Started ${campaign.startDate.day}/${campaign.startDate.month}",
                              style: TextStyle(
                                  color: Colors.grey.shade600),
                            ),
                            Text(
                              "Due ${campaign.dueDate.day}/${campaign.dueDate.month}",
                              style: TextStyle(
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
