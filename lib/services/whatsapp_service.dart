import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/* ================= WHATSAPP SERVICE ================= */
class WhatsAppService {
  static const String baseUrl =
      "http://10.169.30.216:3000/api/message-templates";

  /* ================= OPEN TEMPLATE PICKER ================= */
  static Future<void> openTemplatePicker(
      BuildContext context,
      String leadName,
      String phoneNumber,
      ) async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode != 200) {
        _showError(context, "Failed to load message templates");
        return;
      }

      final List templates = jsonDecode(response.body);

      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) {
          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];

              return ListTile(
                title: Text(template["name"] ?? "Unnamed Template"),
                subtitle: Text(
                  template["message"] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.pop(context);

                  final variables =
                  template["variables"] is String
                      ? List<String>.from(
                      jsonDecode(template["variables"]))
                      : List<String>.from(template["variables"] ?? []);

                  openVariableDialog(
                    context,
                    template["id"],
                    phoneNumber,
                    variables,
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint("WhatsApp template error: $e");
      _showError(context, "Error loading templates");
    }
  }

  /* ================= VARIABLE INPUT DIALOG ================= */
  static void openVariableDialog(
      BuildContext context,
      int templateId,
      String phoneNumber,
      List<String> variables,
      ) {
    showDialog(
      context: context,
      builder: (_) => _VariableDialog(
        templateId: templateId,
        phoneNumber: phoneNumber,
        variables: variables,
      ),
    );
  }

  /* ================= SEND MESSAGE ================= */
  static Future<void> sendWhatsAppMessage(
      int templateId,
      String phoneNumber,
      List<String> values,
      ) async {
    try {
      final formattedPhone = _formatPhone(phoneNumber);

      final response = await http.post(
        Uri.parse("$baseUrl/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "templateId": templateId,
          "phoneNumber": formattedPhone,
          "values": values,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data["whatsappUrl"];
        await _launchUrl(Uri.parse(url));
      } else {
        throw "Failed to generate WhatsApp link";
      }
    } catch (e) {
      debugPrint("WhatsApp send error: $e");
      rethrow;
    }
  }

  /* ================= HELPERS ================= */
  static String _formatPhone(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }

    if (!clean.startsWith('+')) {
      if (clean.length == 10) {
        clean = '+91$clean';
      } else if (clean.startsWith('91')) {
        clean = '+$clean';
      }
    }
    return clean;
  }

  static Future<void> _launchUrl(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "Cannot open WhatsApp";
    }
  }

  static void _showError(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }
}

/* ================= VARIABLE DIALOG WIDGET ================= */
class _VariableDialog extends StatefulWidget {
  final int templateId;
  final String phoneNumber;
  final List<String> variables;

  const _VariableDialog({
    required this.templateId,
    required this.phoneNumber,
    required this.variables,
  });

  @override
  State<_VariableDialog> createState() => _VariableDialogState();
}

class _VariableDialogState extends State<_VariableDialog> {
  late Map<String, TextEditingController> controllers;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    controllers = {
      for (var v in widget.variables) v: TextEditingController()
    };
  }

  @override
  void dispose() {
    for (var c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Fill message details"),
      content: SingleChildScrollView(
        child: Column(
          children: widget.variables.map((v) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: controllers[v],
                decoration: InputDecoration(
                  labelText: v.replaceAll("_", " "),
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSending ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isSending ? null : _send,
          child: isSending
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text("Open WhatsApp"),
        ),
      ],
    );
  }

  Future<void> _send() async {
    setState(() => isSending = true);

    try {
      final values =
      widget.variables.map((v) => controllers[v]!.text).toList();

      Navigator.pop(context);

      await WhatsAppService.sendWhatsAppMessage(
        widget.templateId,
        widget.phoneNumber,
        values,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to open WhatsApp"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }
}
