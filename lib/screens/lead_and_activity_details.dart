import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:internship_app/models/lead_model.dart';
import 'package:internship_app/models/lead_activity_model.dart';
import 'package:internship_app/services/lead_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  void _showAddCallDialog() {
    TextEditingController callController = TextEditingController(
      text:
      'Call to ${widget.lead.phone} at ${DateFormat('hh:mm a').format(DateTime.now())}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Call Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: callController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter call details...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text('Call to: ${widget.lead.phone}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (callController.text.isNotEmpty) {
                await _addActivity(
                  'call',
                  'Outgoing Call',
                  callController.text,
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Call logged successfully')),
                );

                await loadActivities();
              }
            },
            child: const Text('Log Call'),
          ),
        ],
      ),
    );
  }


  void _showAddMessageDialog() {
    TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your message...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text('To: ${widget.lead.phone}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                _addActivity('email', 'Message Sent', messageController.text);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message logged successfully')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
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

  void _makePhoneCall() {
    // For actual phone calls, you'd use url_launcher package
    // For now, we'll just log the call activity
    _showAddCallDialog();
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
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              // Edit lead functionality - you can implement this later
            },
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Leads'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Campaigns'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _profileCard(),
            const SizedBox(height: 16),
            _actionButtons(),
            const SizedBox(height: 20),
            _activityHeader(),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (activities.isEmpty)
              const Center(child: Text("No activities found"))
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
        child: const Icon(Icons.note_add),
      ),
    );
  }

  Widget _profileCard() {
    Color statusColor;
    switch (widget.lead.status) {
      case 'New Lead':
        statusColor = Colors.blue;
        break;
      case 'Interested':
        statusColor = Colors.green;
        break;
      case 'Call Back':
        statusColor = Colors.orange;
        break;
      case 'Converted':
        statusColor = Colors.purple;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.lead.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            widget.lead.phone,
            style: const TextStyle(color: Colors.grey),
          ),
          if (widget.lead.email != null && widget.lead.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.lead.email!,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
          if (widget.lead.company != null && widget.lead.company!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.lead.company!,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip(widget.lead.status, statusColor.withOpacity(0.15), statusColor),
              const SizedBox(width: 8),
              _chip(
                  'Last: ${widget.lead.lastActivity}',
                  Colors.grey.withOpacity(0.15),
                  Colors.grey
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12),
      ),
    );
  }

  Widget _actionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _makePhoneCall,
            child: _actionButton(Icons.call, 'Call', Colors.blue),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _showAddMessageDialog,
            child: _actionButton(Icons.chat, 'Message', Colors.green),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _showStatusChangeDialog,
            child: _actionButton(Icons.sync, 'Status', Colors.orange),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _activityHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Activity History',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        TextButton(
          onPressed: loadActivities,
          child: const Text(
            'Refresh',
            style: TextStyle(color: Colors.blue),
          ),
        )
      ],
    );
  }

  Widget _activityItem(LeadActivity activity) {
    IconData icon;
    Color color;

    switch (activity.type) {
      case 'call':
        icon = Icons.call;
        color = Colors.blue;
        break;
      case 'email':
        icon = Icons.email;
        color = Colors.purple;
        break;
      case 'note':
        icon = Icons.note;
        color = Colors.orange;
        break;
      case 'status':
        icon = Icons.sync;
        color = Colors.green;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(activity.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (activity.description != null && activity.description!.isNotEmpty)
                  Text(
                    activity.description!,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                const SizedBox(height: 4),
                Text(
                  'By: ${activity.user} • ${DateFormat('dd MMM yyyy').format(activity.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}