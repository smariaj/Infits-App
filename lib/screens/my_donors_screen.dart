import 'package:flutter/material.dart';
import 'package:internship_app/models/donors.dart';
import 'donor_details_scrren.dart';

/// --------------------
/// MOCK BACKEND
/// --------------------
class DonorRepository {
  static List<Donor> getDonors() {
    return [
      Donor(
        name: "Sarah Jenkins",
        isActive: true,
        totalLifetimeGiving: 1250,
        phone: "+1 (555) 019-2834",
        email: "sarah@gmail.com",
        address: "New York, USA",
        donations: [
          Donation(
            title: "Education Fund",
            date: DateTime(2023, 10, 24),
            amount: 500,
            completed: true,
          ),
        ],
      ),
      Donor(
        name: "Michael Chen",
        isActive: false,
        totalLifetimeGiving: 450,
        phone: "+1 (555) 882-1920",
        email: "michael@gmail.com",
        address: "San Francisco, USA",
        donations: [
          Donation(
            title: "Health Camp",
            date: DateTime(2023, 11, 2),
            amount: 450,
            completed: true,
          ),
        ],
      ),
    ];
  }
}

/// --------------------
/// FILTER TYPES
/// --------------------
enum DonorFilter { all, recent, highValue }

/// --------------------
/// MAIN SCREEN
/// --------------------
class MyDonorsScreen extends StatefulWidget {
  const MyDonorsScreen({super.key});

  @override
  State<MyDonorsScreen> createState() => _MyDonorsScreenState();
}

class _MyDonorsScreenState extends State<MyDonorsScreen> {
  late List<Donor> allDonors;
  late List<Donor> donors;
  DonorFilter selectedFilter = DonorFilter.all;

  @override
  void initState() {
    super.initState();
    allDonors = DonorRepository.getDonors();
    donors = List.from(allDonors);
  }

  void applyFilter(DonorFilter filter) {
    setState(() {
      selectedFilter = filter;

      if (filter == DonorFilter.all) {
        donors = List.from(allDonors);
      }
      else if (filter == DonorFilter.recent) {
        donors = List.from(allDonors)
          ..sort((a, b) =>
              b.donations.last.date.compareTo(a.donations.last.date));
      }
      else if (filter == DonorFilter.highValue) {
        donors = List.from(allDonors)
          ..sort((a, b) =>
              b.totalLifetimeGiving.compareTo(a.totalLifetimeGiving));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("My Donors"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// Search
            TextField(
              decoration: InputDecoration(
                hintText: "Search name or number...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// Filters (scrollable)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(
                    "All Donors",
                    selected: selectedFilter == DonorFilter.all,
                    onTap: () => applyFilter(DonorFilter.all),
                  ),
                  _filterChip(
                    "Recent Donation",
                    selected: selectedFilter == DonorFilter.recent,
                    onTap: () => applyFilter(DonorFilter.recent),
                  ),
                  _filterChip(
                    "High Value",
                    selected: selectedFilter == DonorFilter.highValue,
                    onTap: () => applyFilter(DonorFilter.highValue),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// Donor List
            Expanded(
              child: ListView.builder(
                itemCount: donors.length,
                itemBuilder: (context, index) {
                  final donor = donors[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DonorDetailsScreen(donor: donor),
                        ),
                      );
                    },
                    child: _donorCard(donor),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Leads'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Campaigns'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Call Stats'),
        ],
      ),
    );
  }

  /// --------------------
  /// UI HELPERS
  /// --------------------
  Widget _filterChip(String text,
      {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.blue : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _donorCard(Donor donor) {
    final lastDonation = donor.donations.isNotEmpty
        ? donor.donations.last
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              donor.name[0],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(donor.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  donor.phone,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (lastDonation != null)
                  Text(
                    "Last: ${lastDonation.title}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "LIFETIME",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                "₹${donor.totalLifetimeGiving.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFEAF6FF),
                child: Icon(Icons.call, size: 16, color: Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
