import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CreateWhatsAppTemplateScreen extends StatefulWidget {
  const CreateWhatsAppTemplateScreen({super.key});

  @override
  State<CreateWhatsAppTemplateScreen> createState() =>
      _CreateWhatsAppTemplateScreenState();
}

class _CreateWhatsAppTemplateScreenState
    extends State<CreateWhatsAppTemplateScreen> {
  // ================= CONTROLLERS =================
  final String baseUrl = "http://10.169.30.216:3000/api/message-templates";

  final TextEditingController templateNameController =
      TextEditingController();
  final TextEditingController messageController =
      TextEditingController();

  File? headerAttachment;

  // ================= VARIABLES =================

  final List<String> variables = [
    "customer_name",
    "telecaller_name",
    "campaign_name",
  ];


  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create WhatsApp Template"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _templateName(),
            const SizedBox(height: 16),
            _infoBox(),
            const SizedBox(height: 16),
            _headerAttachment(),
            const SizedBox(height: 16),
            _messageEditor(),
            const SizedBox(height: 12),
            _actionButtons(),
            // const SizedBox(height: 20),
            // _whatsAppPreview(),
          ],
        ),
      ),
    );
  }

  // ================= UI SECTIONS =================

  Widget _templateName() {
    return TextField(
      controller: templateNameController,
      decoration: const InputDecoration(
        labelText: "Template Name",
        hintText: "e.g. Welcome Message - Campaign A",
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Using Dynamic Variables\nPersonalize your WhatsApp messages using variables like {{customer_name}}.",
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerAttachment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Header Attachment (Optional)",
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickHeaderAttachment,
          child: Container(
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: headerAttachment == null
                ? const Text("Click to upload or drag and drop")
                : Text(headerAttachment!.path.split('/').last),
          ),
        ),
      ],
    );
  }

  Widget _messageEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Message Content",
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        _formattingBar(),
        const SizedBox(height: 6),
        TextField(
          controller: messageController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText:
                "Hi {{customer_name}}, this is {{telecaller_name}}...",
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "${messageController.text.length} characters",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _formattingBar() {
    return Row(
      children: [
        _formatButton("B", "*"),
        _formatButton("I", "_"),
        _formatButton("S", "~"),
        const Spacer(),
        PopupMenuButton<String>(
          onSelected: _insertVariable,
          itemBuilder: (_) => variables
              .map(
                (v) => PopupMenuItem(
                  value: v,
                  child: Text(v),
                ),
              )
              .toList(),
          child: const Chip(
            label: Text("Insert Variable"),
          ),
        ),
      ],
    );
  }

  Widget _formatButton(String label, String wrapper) {
    return IconButton(
      icon: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      onPressed: () => _wrapSelectedText(wrapper),
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _saveTemplate,
            child: const Text("Save Template"),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }

  Widget _whatsAppPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("WhatsApp Preview",
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (headerAttachment != null)
                Container(
                  height: 120,
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Text("Header Media"),
                ),
              const SizedBox(height: 8),
              Text(
                messageController.text.isEmpty
                    ? "Message preview will appear here"
                    : messageController.text,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= LOGIC =================

  void _wrapSelectedText(String wrapper) {
    final selection = messageController.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final text = messageController.text;
    final selected =
        text.substring(selection.start, selection.end);

    final newText = text.replaceRange(
      selection.start,
      selection.end,
      "$wrapper$selected$wrapper",
    );

    messageController.text = newText;
    messageController.selection = TextSelection.collapsed(
      offset: selection.end + wrapper.length * 2,
    );

    setState(() {});
  }

  void _insertVariable(String variable) {
    final cursor = messageController.selection.baseOffset;
    final text = messageController.text;

    final newText =
        text.replaceRange(cursor, cursor, variable);

    messageController.text = newText;
    messageController.selection =
        TextSelection.collapsed(offset: cursor + variable.length);

    setState(() {});
  }

  Future<void> _pickHeaderAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["jpg", "png", "pdf"],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        headerAttachment = File(result.files.single.path!);
      });
    }
  }

  Future<void> _saveTemplate() async {
    if (templateNameController.text.isEmpty ||
        messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all required fields")),
      );
      return;
    }

    final payload = {
      "name": templateNameController.text.trim(),
      "message": messageController.text.trim(),
      "variables": variables,
    };

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Template saved successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save template")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

}
