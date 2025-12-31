import 'package:flutter/material.dart';

// Lead model
class Lead {
  final String initials;
  final String name;
  final String phone;
  final String status;
  final String? lastMessage;

  Lead({
    required this.initials,
    required this.name,
    required this.phone,
    required this.status,
    this.lastMessage,
  });
}

class ContactedLeadsScreen extends StatelessWidget {
  ContactedLeadsScreen({super.key});

  // Example static data (replace with backend later)
  final List<Lead> leads = [
    Lead(
      initials: 'SJ',
      name: 'Sarah Jenkins',
      phone: '+1 123 456 7890',
      status: 'Interested',
      lastMessage: 'Looking for a 2BHK near downtown.',
    ),
    Lead(
      initials: 'MR',
      name: 'Michael Ross',
      phone: '+1 987 654 3210',
      status: 'Callback',
      lastMessage: 'Will call back after 3 PM.',
    ),
    Lead(
      initials: 'JL',
      name: 'Jessica Liu',
      phone: '+1 555 333 2222',
      status: 'No Answer',
    ),
    Lead(
      initials: 'AB',
      name: 'Alex Brown',
      phone: '+1 444 555 6666',
      status: 'Rejected',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'Contacted Leads',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.linear_scale, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: Text(
              'AM',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: 'Search by name or phone number...',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Filter Chips
              Row(
                children: [
                  _filterChip('All', selected: true),
                  const SizedBox(width: 8),
                  _filterChip('Interested'),
                  const SizedBox(width: 8),
                  _filterChip('Callback'),
                  const SizedBox(width: 8),
                  _filterChip('Rejected'),
                ],
              ),

              const SizedBox(height: 20),


              // Lead List
              Expanded(
                child: ListView.builder(
                  itemCount: leads.length,
                  itemBuilder: (context, index) {
                    final lead = leads[index];
                    return _leadCardByStatus(
                      initials: lead.initials,
                      name: lead.name,
                      phone: lead.phone,
                      status: lead.status,
                      lastMessage: lead.lastMessage,
                    );
                  },
                ),
              ),

              // End text

            ],
          ),
        ),
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

  // 🔹 Filter Chip Widget
  static Widget _filterChip(String text, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontSize: 12,
        ),
      ),
    );
  }

  // 🔹 Lead Card Widget by Status
  static Widget _leadCardByStatus({
    required String initials,
    required String name,
    required String phone,
    required String status,
    String? lastMessage,
  }) {
    List<Widget> actionButtons = [];

    if (status == 'Interested') {
      actionButtons = [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Schedule'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[50]),
            child: const Text('Update'),
          ),
        ),
      ];
    } else if (status == 'Callback') {
      actionButtons = [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Call Now'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.linear_scale),
          onPressed: () {},
        ),
      ];
    } else if (status == 'No Answer') {
      actionButtons = [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Try Again'),
          ),
        ),
      ];
    } else if (status == 'Rejected') {
      actionButtons = [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Archive Lead'),
          ),
        ),
      ];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Text(initials),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (lastMessage != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(lastMessage!,style: const TextStyle(fontSize: 12, color: Colors.black87)
                        ),
                      )
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 4),
                decoration:
                BoxDecoration(
                  color: status=='Interested'
                      ? Colors.green.shade100
                      :status=='Callback'
                      ?Colors.orange.shade100
                      :status=='No Answer'
                      ?Colors.blue.shade100
                      :status=='Rejected'
                      ?Colors.red.shade100
                      :Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Text(status,
                style: const TextStyle(fontSize: 10),),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(children: actionButtons),
        ],
      ),
    );
  }
}
