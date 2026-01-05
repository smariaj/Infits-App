import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../models/campaignrepo.dart';

class CampaignsScreen extends StatefulWidget {
  final String agentId;

  const CampaignsScreen({super.key, required this.agentId});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  List<Campaign> allCampaigns = [];
  List<Campaign> visibleCampaigns = [];
  String selectedFilter = "Active";
  String searchQuery = "";
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() => isLoading = true);
    try {
      final campaigns =
      await CampaignRepository.fetchCampaignsForAgent(widget.agentId);
      setState(() {
        allCampaigns = campaigns;
        _applyFilter();
        errorMessage = "";
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load campaigns";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      visibleCampaigns = allCampaigns.where((c) {
        bool statusMatch;
        if (selectedFilter == "All") {
          statusMatch = true;
        } else if (selectedFilter == "Inactive") {
          statusMatch = c.status.toLowerCase() == "paused";
        } else {
          statusMatch = c.status.toLowerCase() == selectedFilter.toLowerCase();
        }

        bool searchMatch = c.title.toLowerCase().contains(searchQuery.toLowerCase());

        return statusMatch && searchMatch;
      }).toList();
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return Colors.green;
      case "paused":
        return Colors.orange;
      case "completed":
        return Colors.blue;
      case "draft":
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(child: Text(errorMessage)),
      );
    }

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
              onChanged: (val) {
                searchQuery = val;
                _applyFilter();
              },
            ),
          ),

          /// 🔘 Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ["Active", "Inactive", "Draft", "Completed", "All"]
                  .map((filter) {
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
            child: visibleCampaigns.isEmpty
                ? const Center(child: Text("No campaigns available"))
                : ListView.builder(
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
                          "Audience: ${campaign.demographics.isNotEmpty ? campaign.demographics : 'N/A'}",
                          style: TextStyle(color: Colors.grey.shade600),
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
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                "${campaign.called}/${campaign.target} Called"),
                            Text(
                              "Started ${campaign.startDate.day}/${campaign.startDate.month}",
                              style:
                              TextStyle(color: Colors.grey.shade600),
                            ),
                            Text(
                              "Due ${campaign.dueDate.day}/${campaign.dueDate.month}",
                              style:
                              TextStyle(color: Colors.grey.shade600),
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
