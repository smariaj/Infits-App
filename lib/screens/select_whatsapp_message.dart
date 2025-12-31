import 'package:flutter/material.dart';

class WhatsAppTemplate {
  final String title;
  final String content;
  final String type; // "Marketing", "Utility", "Authentication"
  final String status; // "Approved", "Pending", "Rejected"

  WhatsAppTemplate({
    required this.title,
    required this.content,
    required this.type,
    required this.status,
  });
}

class SelectWhatsAppTemplateScreen extends StatefulWidget {
  const SelectWhatsAppTemplateScreen({super.key});

  @override
  State<SelectWhatsAppTemplateScreen> createState() =>
      _SelectWhatsAppTemplateScreenState();
}

class _SelectWhatsAppTemplateScreenState
    extends State<SelectWhatsAppTemplateScreen> {
  List<WhatsAppTemplate> templates = [
    WhatsAppTemplate(
        title: "Welcome Message",
        content: "Hi [name], welcome to our service!",
        type: "Marketing",
        status: "Approved"),
    WhatsAppTemplate(
        title: "OTP Verification",
        content: "Your OTP is [OTP]",
        type: "Authentication",
        status: "Pending"),
    WhatsAppTemplate(
        title: "Reminder",
        content: "Hi [name], this is a reminder for your appointment",
        type: "Utility",
        status: "Rejected"),
    WhatsAppTemplate(
        title: "Promotion Offer",
        content: "Get 20% off on your next purchase",
        type: "Marketing",
        status: "Approved"),
  ];

  String selectedFilter = "All";
  WhatsAppTemplate? selectedTemplate;
  String searchQuery = "";

  List<String> filters = ["All", "Marketing", "Utility", "Authentication"];

  List<WhatsAppTemplate> get filteredTemplates {
    List<WhatsAppTemplate> temp = templates;

    // Filter by type
    if (selectedFilter != "All") {
      temp = temp.where((t) => t.type == selectedFilter).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      temp = temp
          .where((t) =>
      t.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.content.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return temp;
  }

  Color statusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Pending":
        return Colors.orange;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void navigateToEditScreen(WhatsAppTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTemplateScreen(messageText: template.content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select WhatsApp Template"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search by name or content",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(),
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Buttons
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  String filter = filters[index];
                  bool isSelected = filter == selectedFilter;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isSelected ? Colors.blue : Colors.grey[200],
                      foregroundColor:
                      isSelected ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                    child: Text(filter),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Template List
            Expanded(
              child: filteredTemplates.isEmpty
                  ? const Center(
                child: Text("No templates found"),
              )
                  : ListView.separated(
                itemCount: filteredTemplates.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  var template = filteredTemplates[index];
                  bool isSelected = template == selectedTemplate;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        // Toggle selection
                        if (isSelected) {
                          selectedTemplate = null;
                        } else {
                          selectedTemplate = template;
                          navigateToEditScreen(template); // Navigate on select
                        }
                      });
                    },
                    child: Card(
                      color:
                      isSelected ? Colors.blue.withOpacity(0.3) : null,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        // Status Text instead of dot
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor(template.status)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            template.status,
                            style: TextStyle(
                              color: statusColor(template.status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(template.title),
                        subtitle: Text(template.content),
                        trailing: ElevatedButton(
                          onPressed: () {
                            navigateToEditScreen(template);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? Colors.blue
                                : Colors.grey[200],
                            foregroundColor:
                            isSelected ? Colors.white : Colors.black,
                            minimumSize: const Size(70, 30),
                            padding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 8),
                          ),
                          child: const Text("Select",
                              style: TextStyle(fontSize: 12)),
                        ),
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

class EditTemplateScreen extends StatefulWidget {
  final String messageText;

  const EditTemplateScreen({super.key, required this.messageText});

  @override
  State<EditTemplateScreen> createState() => _EditTemplateScreenState();
}

class _EditTemplateScreenState extends State<EditTemplateScreen> {

  late TextEditingController bigEditController;

  @override
  void initState() {
    super.initState();

    bigEditController = TextEditingController(text: widget.messageText);
  }

  void insertVariable(String variable) {
    final text = bigEditController.text;
    final selection = bigEditController.selection;
    final newText =
    text.replaceRange(selection.start, selection.end, "[$variable]");
    final newPosition = selection.start + variable.length + 2;

    bigEditController.text = newText;
    bigEditController.selection =
        TextSelection.fromPosition(TextPosition(offset: newPosition));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Message"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Editable message text

            const SizedBox(height: 16),

            // Big multi-line editable text
            Expanded(
              child: TextField(
                controller: bigEditController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  hintText: "Edit full message here...",
                ),
              ),
            ),
            const SizedBox(height: 12),

         SingleChildScrollView(
           scrollDirection: Axis.horizontal,
           child: Row(
             children: [
               ElevatedButton(
                 onPressed: () => insertVariable("Name"),
                 child: const Text("Name"),
               ),
               ElevatedButton(
                 onPressed: () => insertVariable("Date"),
                 child: const Text("Date"),
               ),
               ElevatedButton(
                 onPressed: () => insertVariable("Phone"),
                 child: const Text("Phone"),
               ),
               ElevatedButton(
                 onPressed: () => insertVariable("City"),
                 child: const Text("City"),
               ),
             ],
           ),
           ),


            const SizedBox(height: 16),

            // Send via WhatsApp button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement WhatsApp sending logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text("Send via WhatsApp"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
