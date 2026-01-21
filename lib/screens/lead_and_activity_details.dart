import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:internship_app/models/lead_model.dart';
import 'package:internship_app/models/lead_activity_model.dart';
import 'package:internship_app/services/lead_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:internship_app/screens//campaign_progess_notifier.dart';

import 'dart:convert';

// Import WhatsAppService
import 'package:internship_app/screens/all_leads_overview.dart';

class LeadDetailsScreen extends StatefulWidget {
  final Lead lead;
  final VoidCallback? onLeadUpdated;

  const LeadDetailsScreen({
    super.key,
    required this.lead,
    this.onLeadUpdated,
  });

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  List<LeadActivity> activities = [];
  bool isLoading = true;
  int? loggedInUserId;
  String? loggedInUserName;

  @override
  void initState() {
    super.initState();
    loadUserAndActivities();
  }

  Future<void> loadUserAndActivities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    loggedInUserId = prefs.getInt("user_id");
    loggedInUserName = prefs.getString("user_name") ?? "Agent";

    if (loggedInUserId != null) {
      loadActivities();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadActivities() async {
    try {
      final data = await LeadService.getLeadActivities(widget.lead.id);
      setState(() {
        activities = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Failed to load activities: $e');
    }
  }

  Future<void> _addActivity(String type, String title, String? description) async {
    try {
      final response = await http.post(
        Uri.parse('${LeadService.baseUrl}/lead_activities/lead-activities'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lead_id': widget.lead.id,
          'type': type,
          'title': title,
          'description': description,
          'user': loggedInUserName!,
        }),
      );

      if (response.statusCode == 201) {
        await loadActivities();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title added successfully')),
        );
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add activity')),
      );
    }
  }

  Future<void> _updateLeadStatus(String newStatus) async {
    final oldStatus = widget.lead.status;

    try {
      final response = await http.put(
        Uri.parse('${LeadService.baseUrl}/leads/${widget.lead.id}/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          widget.lead.status = newStatus;
        });

        await _addActivity(
          'status',
          'Status Changed',
          'Status changed from $oldStatus to $newStatus',
        );

        widget.onLeadUpdated?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status update failed')),
      );
    }
  }

  void _showAddNoteDialog() {
    TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: noteController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter your note here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.isNotEmpty) {
                _addActivity('note', 'Note Added', noteController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  Future<void> _logPhoneCall() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString("user_name") ?? "Unknown";

    TextEditingController notesController = TextEditingController();
    DateTime? callTime;
    Duration? callDuration;

    // Ask for call details BEFORE making the call
    final details = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Log Call'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You are about to call: ${widget.lead.phone}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Call purpose or notes (optional)...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => callTime = DateTime.now());
                        },
                        icon: const Icon(Icons.timer, size: 16),
                        label: Text(callTime == null
                            ? 'Set call time'
                            : DateFormat('hh:mm a').format(callTime!)
                        ),
                      ),
                      const SizedBox(width: 8),

                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'notes': notesController.text,
                      'callTime': callTime,
                      'duration': callDuration,
                    });
                  },
                  child: const Text('Log & Call'),
                ),
              ],
            );
          },
        );
      },
    );

    if (details != null) {
      // Open phone dialer
      final uri = Uri(scheme: 'tel', path: widget.lead.phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);

        // Log the call activity
        String description = 'Called ${widget.lead.phone}';
        if (details['notes'] != null && details['notes'].toString().isNotEmpty) {
          description += '\nNotes: ${details['notes']}';
        }
        if (details['duration'] != null) {
          final duration = details['duration'] as Duration;
          description += '\nDuration: ${duration.inMinutes}m ${duration.inSeconds % 60}s';
        }

        await _addActivity('call', 'Outgoing Call', description);

        // Also log via LeadService for backend
        try {
          await LeadService.logCallActivity(
            leadId: widget.lead.id,
            userName: userName,
          );

          // If the lead is part of a campaign, notify the campaign screen
          // If the lead is part of a campaign, notify the campaign screen
          if (widget.lead.campaignId != null) {
            final intId = int.tryParse(widget.lead.campaignId!);
            if (intId != null) {
              campaignProgressNotifier.markUpdated(intId);
            }
          }


        } catch (e) {
          print('Error in LeadService.logCallActivity: $e');
        }
      }
    }
  }

  void _showWhatsAppTemplatePicker() async {
    await WhatsAppService.openTemplatePicker(context, widget.lead.name, widget.lead.phone);
  }

  void _showStatusChangeDialog() {
    List<String> statuses = ['New Lead', 'Interested', 'Call Back', 'Converted'];
    String? selectedStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Change Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current status: ${widget.lead.status}'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items: statuses.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedStatus = value),
                  decoration: const InputDecoration(
                    labelText: 'New Status',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedStatus != null) {
                    await _updateLeadStatus(selectedStatus!);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New Lead':
        return Colors.blue;
      case 'Interested':
        return Colors.green;
      case 'Call Back':
        return Colors.orange;
      case 'Converted':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lead Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              // Edit lead functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: loadActivities,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card - CENTERED
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.lead.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.lead.phone,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.lead.email != null && widget.lead.email!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.lead.email!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (widget.lead.company != null && widget.lead.company!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.lead.company!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Status Badge - Centered
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.lead.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.lead.status,
                        style: TextStyle(
                          color: _getStatusColor(widget.lead.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Actions - CENTERED
            const Center(
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton(
                  icon: Icons.call,
                  label: 'Call',
                  color: Colors.blue,
                  onTap: _logPhoneCall,
                ),
                const SizedBox(width: 16),
                _actionButton(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  color: Colors.green,
                  onTap: _showWhatsAppTemplatePicker,
                ),
                const SizedBox(width: 16),
                _actionButton(
                  icon: Icons.sync,
                  label: 'Status',
                  color: Colors.orange,
                  onTap: _showStatusChangeDialog,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Activity History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: loadActivities,
                  child: const Text(
                    'Refresh',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (activities.isEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.history, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No activities yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: activities.map(_activityItem).toList(),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _showAddNoteDialog,
        child: const Icon(Icons.note_add, color: Colors.white),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityItem(LeadActivity activity) {
    IconData icon;
    Color color;
    String typeLabel;

    switch (activity.type) {
      case 'call':
        icon = Icons.call;
        color = Colors.blue;
        typeLabel = 'Call';
        break;
      case 'email':
        icon = Icons.email;
        color = Colors.purple;
        typeLabel = 'Message';
        break;
      case 'note':
        icon = Icons.note;
        color = Colors.orange;
        typeLabel = 'Note';
        break;
      case 'status':
        icon = Icons.sync;
        color = Colors.green;
        typeLabel = 'Status';
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        typeLabel = 'Activity';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (activity.description != null && activity.description!.isNotEmpty)
                  Text(
                    activity.description!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      activity.user,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy • hh:mm a').format(activity.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}