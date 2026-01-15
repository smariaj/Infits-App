import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _currentCallType; // 'in', 'out', 'missed' to prevent duplicates
  DateTime? _lastIncomingCallTime;
  DateTime? _lastOutgoingCallTime;
  DateTime? _callStartTime;

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

  int? _userId;
  String? _token;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();
    await _loadUser();
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
    if (!status.isGranted) debugPrint('Phone permission denied');
  }

  // ---------------- Load logged-in user ----------------
  Future<void> _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt("user_id");
    _token = prefs.getString("jwt_token");
  }

  // ---------------- Phone State Listener ----------------
  void _listenPhoneState() {
    _phoneSub = PhoneState.stream.listen((PhoneState state) async {
      final status = state.status.name;
      final now = DateTime.now();

      debugPrint('--- PhoneState update ---');
      debugPrint('Status: $status');
      debugPrint('Last status: $_lastStatus');
      debugPrint('Current call type: $_currentCallType');
      debugPrint('Is incoming: $_isIncomingCall, Call connected: $_callConnected');

      // ---------------- Incoming call ----------------
      if (status == 'CALL_INCOMING') {
        if (_lastIncomingCallTime == null ||
            now.difference(_lastIncomingCallTime!).inSeconds > 2) {
          _lastIncomingCallTime = now;
          _isIncomingCall = true;
          _callConnected = false;
          _callStartTime = now;

          if (_currentCallType == null) {
            _currentCallType = 'in';
            setState(() {
              callStats['in']++;
              callStats['allCalls']++;
              _updateTimestamps();
            });

            Future.microtask(() async {
              // Missed? Duration 0 for now; will be updated on CALL_ENDED
              await _logCall(type: "in", connected: false, startTime: _callStartTime, endTime: now);
            });
          }
        }
      }

      // ---------------- Call started ----------------
      else if (status == 'CALL_STARTED') {
        _callStartTime ??= now; // start timing if not already

        // Answered incoming
        if (_lastStatus == 'CALL_INCOMING' && _isIncomingCall && !_callConnected) {
          _callConnected = true;
          setState(() {
            callStats['connected']++;
            _updateProgress();
          });
          Future.microtask(() async {
            if (_currentCallType == 'in') {
              await _logCall(type: "in", connected: true, startTime: _callStartTime, endTime: now);
            }
          });
        }

        // Outgoing call
        else if (_lastStatus == null || _lastStatus == 'CALL_ENDED') {
          if (_lastOutgoingCallTime == null ||
              now.difference(_lastOutgoingCallTime!).inSeconds > 2) {
            _lastOutgoingCallTime = now;
            _isIncomingCall = false;
            _callConnected = true;
            _callStartTime ??= now;

            if (_currentCallType == null) {
              _currentCallType = 'out';
              Future.delayed(const Duration(seconds: 1), () async {
                if (!mounted) return;
                setState(() {
                  callStats['out']++;
                  callStats['allCalls']++;
                  callStats['connected']++;
                  _updateProgress();
                });
                await _logCall(
                  type: "out",
                  connected: true,
                  startTime: _callStartTime,
                  endTime: DateTime.now(),
                );
              });
            }
          }
        }
      }

      // ---------------- Call ended ----------------
      else if (status == 'CALL_ENDED') {
        final callEndTime = now;

        int durationSeconds = 0;
        if (_callStartTime != null) {
          durationSeconds = callEndTime.difference(_callStartTime!).inSeconds;
        }

        // Missed incoming
        if (_lastStatus == 'CALL_INCOMING' && _isIncomingCall && !_callConnected) {
          if (_currentCallType != 'missed') {
            _currentCallType = 'missed';
            setState(() {
              callStats['missed']++;
            });
            await _logCall(
              type: "missed",
              connected: false,
              startTime: _callStartTime,
              endTime: callEndTime,
            );
          }
        }

        // Reset flags
        _isIncomingCall = false;
        _callConnected = false;
        _currentCallType = null;
        _callStartTime = null;
      }

      _lastStatus = status;
      debugPrint('--- End PhoneState update ---\n');
    });
  }

  void _updateTimestamps() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (callStats['firstCall'] == '-') callStats['firstCall'] = timeStr;
    callStats['lastCall'] = timeStr;
  }

  void _updateProgress() {
    final connected = callStats['connected'] as int;
    final dailyGoal = callStats['dailyGoal'] as int;
    callStats['remaining'] = (dailyGoal - connected).clamp(0, dailyGoal);
  }

  // ---------------- Backend Integration ----------------
  Future<void> _logCall({
    required String type,
    required bool connected,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    if (_userId == null) return;

    final durationSeconds = (startTime != null && endTime != null)
        ? endTime.difference(startTime).inSeconds
        : 0;

    final callData = {
      "user_id": _userId,
      "type": type,
      "connected": connected,
      "duration": durationSeconds,
    };

    debugPrint('Logging call to backend: $callData');

    try {
      final response = await http.post(
        Uri.parse("http://10.169.30.222:3000/call-stats/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(callData),
      );
      debugPrint('Backend response: ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint('Failed to log call: $e');
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
            Row(
              children: [
                Expanded(
                  child: _callTimeCard(
                    'First Call',
                    callStats['firstCall'].toString(),
                    Icons.call_received,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _callTimeCard(
                    'Last Call',
                    callStats['lastCall'].toString(),
                    Icons.call_made,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'All Calls',
                    count: callStats['allCalls'],
                    icon: Icons.phone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    title: 'Target',
                    count: callStats['dailyGoal'],
                    icon: Icons.flag,
                    connected: callStats['connected'],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'In',
                    count: callStats['in'],
                    icon: Icons.call_received,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    title: 'Out',
                    count: callStats['out'],
                    icon: Icons.call_made,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    title: 'Missed',
                    count: callStats['missed'],
                    icon: Icons.call_missed,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Goal Progress - ${(progress * 100).toInt()}% completed',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
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
            _currentCallType = null;
            _lastIncomingCallTime = null;
            _lastOutgoingCallTime = null;
            _callStartTime = null;
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
          Text('$count',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (title == 'Target') ...[
            const SizedBox(height: 4),
            Text('Connected $connected',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Widget _callTimeCard(
      String title, String time, IconData icon, Color iconColor) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration:
      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
