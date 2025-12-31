import 'package:flutter/material.dart';
import 'package:internship_app/models/donors.dart';





class DonorDetailsScreen extends StatelessWidget {
  final Donor donor;

  const DonorDetailsScreen({super.key, required this.donor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Donor Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// ---------- TOP CARD ----------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.orange.shade100,
                    child: Text(
                      donor.name[0],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    donor.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: donor.isActive
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      donor.isActive ? 'Active Donor' : 'Inactive',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Lifetime Giving',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${donor.totalLifetimeGiving.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ---------- ACTION BUTTONS ----------
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _cardDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _ActionIcon(icon: Icons.call, label: 'Call'),
                  _ActionIcon(icon: Icons.message, label: 'Message'),
                  _ActionIcon(icon: Icons.email, label: 'Email'),
                  _ActionIcon(icon: Icons.edit, label: 'Edit'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ---------- CONTACT DETAILS ----------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONTACT DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _infoRow(Icons.phone, donor.phone),
                  _infoRow(Icons.email, donor.email),
                  _infoRow(Icons.location_on, donor.address),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ---------- TRANSACTIONS ----------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TRANSACTIONS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${donor.donations.length} Records',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  ...donor.donations.map(_donationTile).toList(),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      'View All Donations',
                      style: TextStyle(color: Colors.blue.shade600),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------- HELPERS ----------

  static BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  static Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  static Widget _donationTile(Donation donation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(donation.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${donation.date.day}/${donation.date.month}/${donation.date.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '+₹${donation.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- ACTION ICON ----------
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
