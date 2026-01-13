import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'create-template.dart';

class MessageTemplate {
  final String title;
  final String content;

  MessageTemplate({
    required this.title,
    required this.content,
  });
}


class MessageTemplateScreen extends StatefulWidget {
  const MessageTemplateScreen({super.key});

  @override
  State<MessageTemplateScreen> createState() => _MessageTemplateScreenState();
}

class _MessageTemplateScreenState extends State<MessageTemplateScreen> {
  final String baseUrl = "http://10.0.2.2:3000/api/message-templates";

  List<MessageTemplate> templates = [];

  Future<void> _loadTemplates() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List list = json.decode(response.body);

        setState(() {
          templates = list
              .map((e) => MessageTemplate(
            title: e["name"].toString(),
            content: e["message"].toString(),
          ))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Failed to load templates: $e");
    }
  }
  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  String selectedFilter = "All";
  String searchQuery = "";

  List<String> filters = ["All", "Follow Up", "Cold Call", "Meeting"];

  List<MessageTemplate> get filteredTemplates {
    List<MessageTemplate> temp = templates;

    if (searchQuery.isNotEmpty) {
      temp = temp
          .where((t) =>
      t.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.content.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
    return temp;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Message Template"),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
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
                hintText: "Search templates",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
            // Message List
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
                  var message = filteredTemplates[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text(message.title),
                      subtitle: Text(message.content),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action when + is pressed

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateWhatsAppTemplateScreen()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
        mini: true, // makes it small
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Leads'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Campaigns'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Call Stats'),
        ],
      ),
    );
  }
}
