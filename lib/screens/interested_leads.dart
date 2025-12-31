import 'package:flutter/material.dart';

// Lead model
class Lead {
  final String initials;
  final String name;
  final String subtitle;
  final String status;

  Lead({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.status,
  });
}

class InterestedLeadsScreen extends StatelessWidget {
  InterestedLeadsScreen({super.key});

  // Example static data (later replace with backend fetch)
  final List<Lead> leads = [
    Lead(
      initials: 'SJ',
      name: 'Sarah Jenkins',
      subtitle: 'Home Loan . 2 mins ago',
      status: 'Hot',
    ),
    Lead(
      initials: 'MR',
      name: 'Michael Ross',
      subtitle: 'Refinanacing . 1 hour ago',
      status: 'Warm',
    ),
    Lead(
      initials: 'JL',
      name: 'Jessica Liu',
      subtitle: 'Auto Loan. 1 hour ago',
      status: 'Cool',
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 2),
            Text(
              'Interested Leads',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
                    hintText: 'Search by name...',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Filter Chips
              Row(
                children: [
                  _filterChip('All', selected: true),
                  const SizedBox(width: 4),
                  _filterChip('High Interest'),
                  const SizedBox(width: 4),
                  _filterChip('Mortgage'),
                  const SizedBox(width: 4),
                  _filterChip('Insurance'),
                ],
              ),

              const SizedBox(height: 20),


              // Dynamic Lead List
              Expanded(
                child: ListView.builder(
                  itemCount: leads.length,
                  itemBuilder: (context, index) {
                    final lead = leads[index];
                    return _leadCard(
                      initials: lead.initials,
                      name: lead.name,
                      subtitle: lead.subtitle,
                      status: lead.status,
                      primaryButton: 'Call Lead',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Leads'),
          BottomNavigationBarItem(
              icon: Icon(Icons.campaign), label: 'Campaigns'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Call Stats'),
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

  // 🔹 Lead Card Widget
  static Widget _leadCard({
    required String initials,
    required String name,
    required String subtitle,
    required String status,
    required String primaryButton,
  }) {
    // 1️⃣ Determine status color
    Color statusColor;
    switch (status) {
      case 'Hot':
        statusColor = Colors.red.shade100;
        break;
      case 'Warm':
        statusColor = Colors.orange.shade100;
        break;
      case 'Cool':
        statusColor = Colors.blue.shade100;
        break;
      default:
        statusColor = Colors.green.shade100;
    }

    // 2️⃣ Determine action buttons
    List<Widget> actionButtons = [];

    if (status == 'Hot' || status == 'Warm') {
      // 4 buttons in 2 rows
      actionButtons = [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.call, size: 16),
                label: const Text('Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.email, size: 16),
                label: const Text('Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Nurture Lead'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Convert'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ];
    } else if (status == 'Cool') {
      // 2 buttons in 1 row
      actionButtons = [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Re-Engage'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Archive'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
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
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              // Status container
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 3️⃣ Buttons
          Column(children: actionButtons),
        ],
      ),
    );
  }
}
