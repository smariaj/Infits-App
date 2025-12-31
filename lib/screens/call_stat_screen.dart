import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';

class CallStatsScreen extends StatefulWidget {
  const CallStatsScreen({super.key});

  @override
  State<CallStatsScreen> createState() => _CallStatsScreenState();
}

class _CallStatsScreenState extends State<CallStatsScreen> {
  StreamSubscription<PhoneState>? _phoneSub;
  String? _lastStatus;
  bool _isIncomingCall = false;
  bool _callConnected = false;
  bool _hasProcessedIncoming = false;

  // Track call stats
  Map<String, dynamic> callStats = {
    'firstCall': '-',
    'lastCall': '-',
    'allCalls': 0,
    'connected': 0,
    'in': 0,
    'out': 0,
    'missed': 0,
    'dailyGoal': 10,
    'remaining': 10,
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();
    _listenPhoneState();
  }

  @override
  void dispose() {
    _phoneSub?.cancel();
    super.dispose();
  }

  // ---------------- Permissions ----------------
  Future<void> _requestPermissions() async {
    final status = await Permission.phone.request();
    if (!status.isGranted) {
      debugPrint('Phone permission denied');
    }
  }

  // ---------------- Phone State Listener ----------------
  // ---------------- Phone State Listener ----------------
  void _listenPhoneState() {
    DateTime? _lastIncomingCallTime;

    _phoneSub = PhoneState.stream.listen((PhoneState state) {
      final status = state.status.name;

      debugPrint('Phone State: $status, Last Status: $_lastStatus, IsIncoming: $_isIncomingCall');

      // Handle CALL_INCOMING (incoming call ringing)
      if (status == 'CALL_INCOMING') {
        final now = DateTime.now();

        // Check if this is likely a duplicate event (within 2 seconds of last CALL_INCOMING)
        if (_lastIncomingCallTime == null ||
            now.difference(_lastIncomingCallTime!).inSeconds > 2) {

          _lastIncomingCallTime = now;
          _isIncomingCall = true;
          _callConnected = false;

          setState(() {
            callStats['in'] = (callStats['in'] as int) + 1;
            callStats['allCalls'] = (callStats['allCalls'] as int) + 1;
            _updateTimestamps();
          });
        } else {
          debugPrint('Ignoring duplicate CALL_INCOMING event (too soon)');
        }
      }

      // Handle CALL_STARTED (call picked up/outgoing call started)
      else if (status == 'CALL_STARTED') {
        // Update timestamps
        _updateTimestamps();

        // Check if this is answering an incoming call
        if (_lastStatus == 'CALL_INCOMING' && _isIncomingCall) {
          setState(() {
            callStats['connected'] = (callStats['connected'] as int) + 1;
            _callConnected = true;
            _updateProgress();
          });
        }
        // Check if this is an outgoing call (going from idle to CALL_STARTED)
        else if (_lastStatus == null || _lastStatus == 'CALL_ENDED') {
          // This is an outgoing call
          _isIncomingCall = false;
          setState(() {
            callStats['out'] = (callStats['out'] as int) + 1;
            callStats['allCalls'] = (callStats['allCalls'] as int) + 1;
            callStats['connected'] = (callStats['connected'] as int) + 1;
            _updateProgress();
          });
        }
      }

      // Handle CALL_ENDED (call finished)
      else if (status == 'CALL_ENDED') {
        // Check for missed call (incoming call that ended without being answered)
        if (_lastStatus == 'CALL_INCOMING' && _isIncomingCall && !_callConnected) {
          setState(() {
            callStats['missed'] = (callStats['missed'] as int) + 1;
          });
        }

        // Reset for next call
        _isIncomingCall = false;
        _callConnected = false;
        _lastIncomingCallTime = null;
      }

      _lastStatus = status;
    });
  }

  void _updateTimestamps() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (callStats['firstCall'] == '-') {
      callStats['firstCall'] = timeStr;
    }
    callStats['lastCall'] = timeStr;
  }

  void _updateProgress() {
    final connected = callStats['connected'] as int;
    final dailyGoal = callStats['dailyGoal'] as int;
    callStats['remaining'] = dailyGoal - connected;
    if (callStats['remaining'] < 0) {
      callStats['remaining'] = 0;
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final connected = callStats['connected'] as int;
    final dailyGoal = callStats['dailyGoal'] as int;
    final progress = dailyGoal > 0 ? connected / dailyGoal : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Call Stats',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Call time cards
            Row(
              children: [
                Expanded(
                    child: _callTimeCard(
                        'First Call', callStats['firstCall'].toString(),
                        Icons.call_received, Colors.green)),
                const SizedBox(width: 12),
                Expanded(
                    child: _callTimeCard(
                        'Last Call', callStats['lastCall'].toString(),
                        Icons.call_made, Colors.red)),
              ],
            ),
            const SizedBox(height: 22),
            // Top row
            Row(
              children: [
                Expanded(
                    child: _statCard(
                      title: 'All Calls',
                      count: callStats['allCalls'],
                      icon: Icons.phone,
                      //percentage: '+15%',
                      percentageColor: Colors.green,
                    )),
                const SizedBox(width: 12),
                Expanded(
                    child: _statCard(
                      title: 'Target',
                      count: callStats['dailyGoal'],
                      icon: Icons.flag,
                      connected: callStats['connected'],
                    )),
              ],
            ),
            const SizedBox(height: 22),
            // Second row
            Row(
              children: [
                Expanded(
                    child: _statCard(
                      title: 'In',
                      count: callStats['in'],
                      icon: Icons.call_received,
                      color: Colors.green,
                    )),
                const SizedBox(width: 8),
                Expanded(
                    child: _statCard(
                      title: 'Out',
                      count: callStats['out'],
                      icon: Icons.call_made,
                      color: Colors.blue,
                    )),
                const SizedBox(width: 8),
                Expanded(
                    child: _statCard(
                      title: 'Missed',
                      count: callStats['missed'],
                      icon: Icons.call_missed,
                      color: Colors.red,
                    )),
              ],
            ),
            const SizedBox(height: 22),
            // Daily goal
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Daily Goal Progress - ${(progress * 100).toInt()}% completed',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress > 1.0 ? 1.0 : progress,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.blue,
                  minHeight: 8,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Connected: ${callStats['connected']}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Remaining: ${callStats['remaining']}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            // Reset stats
            callStats = {
              'firstCall': '-',
              'lastCall': '-',
              'allCalls': 0,
              'connected': 0,
              'in': 0,
              'out': 0,
              'missed': 0,
              'dailyGoal': 10,
              'remaining': 10,
            };
            _lastStatus = null;
            _isIncomingCall = false;
            _callConnected = false;
            _hasProcessedIncoming = false;
          });
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  // ---------------- Helpers ----------------
  Widget _statCard({
    required String title,
    required dynamic count,
    required IconData icon,
    String? percentage,
    Color? percentageColor,
    dynamic connected = 0,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: color ?? Colors.blue),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 8),
          Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (percentage != null) ...[
            const SizedBox(height: 4),
            Text(percentage,
                style: TextStyle(fontSize: 12, color: percentageColor, fontWeight: FontWeight.bold)),
          ],
          if (title == 'Target') ...[
            const SizedBox(height: 4),
            Text('Connected $connected', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Widget _callTimeCard(String title, String time, IconData icon, Color iconColor) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
          ]),
          Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}