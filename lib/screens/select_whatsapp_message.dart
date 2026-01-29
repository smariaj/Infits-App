import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:internship_app/services/whatsapp_service.dart';

class SelectWhatsAppTemplateScreen extends StatefulWidget {
  final String phoneNumber;

  const SelectWhatsAppTemplateScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<SelectWhatsAppTemplateScreen> createState() =>
      _SelectWhatsAppTemplateScreenState();
}

class _SelectWhatsAppTemplateScreenState
    extends State<SelectWhatsAppTemplateScreen> {
  static const String baseUrl =
      "http://10.120.217.15:3000/api/message-templates";

  bool isLoading = true;
  List templates = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchTemplates();
  }

  Future<void> fetchTemplates() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        setState(() {
          templates = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw "Failed to load templates";
      }
    } catch (e) {
      debugPrint("Template fetch error: $e");
      setState(() => isLoading = false);
    }
  }

  List get filteredTemplates {
    if (searchQuery.isEmpty) return templates;
    return templates.where((t) {
      return t["name"]
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase()) ||
          t["message"]
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select WhatsApp Template"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // SEARCH
            TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search template",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // LIST
            Expanded(
              child: filteredTemplates.isEmpty
                  ? const Center(child: Text("No templates found"))
                  : ListView.separated(
                itemCount: filteredTemplates.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final template = filteredTemplates[index];

                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(
                        template["name"] ?? "Unnamed",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        template["message"] ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: ElevatedButton(
                        child: const Text("Select"),
                        onPressed: () {
                          Navigator.pop(context);

                          // USE EXISTING SERVICE (IMPORTANT)
                          WhatsAppService.openVariableDialog(
                            context,
                            template["id"],
                            widget.phoneNumber,
                            (template["variables"] is String)
                                ? List<String>.from(
                                jsonDecode(template["variables"]))
                                : List<String>.from(
                                template["variables"] ?? []),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
