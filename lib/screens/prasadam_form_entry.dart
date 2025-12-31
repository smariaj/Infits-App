import 'package:flutter/material.dart';

class ParsadamFormScreen extends StatefulWidget {
  final String telecallerName; // Logged in user

  const ParsadamFormScreen({super.key, required this.telecallerName});

  @override
  State<ParsadamFormScreen> createState() => _ParsadamFormScreenState();
}

class _ParsadamFormScreenState extends State<ParsadamFormScreen> {
  DateTime selectedDate = DateTime.now();
  final TextEditingController donorNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController donatedAmountController = TextEditingController();
  final TextEditingController shippingAddressController = TextEditingController();

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parsadam Form"),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logged By
            const Text("Logged by (Telecaller Name)"),
            const SizedBox(height: 4),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: widget.telecallerName,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date of Donation
            const Text("Date of Donation"),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Donor Name
            const Text("Donor Name"),
            const SizedBox(height: 4),
            TextField(
              controller: donorNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter donor name",
              ),
            ),
            const SizedBox(height: 16),

            // Mobile Number
            const Text("Mobile Number"),
            const SizedBox(height: 4),
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter mobile number",
              ),
            ),
            const SizedBox(height: 16),

            // Donated Amount
            const Text("Donated Amount"),
            const SizedBox(height: 4),
            TextField(
              controller: donatedAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter amount",
              ),
            ),
            const SizedBox(height: 16),

            // Shipping Address
            const Text("Shipping Address"),
            const SizedBox(height: 4),
            TextField(
              controller: shippingAddressController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter shipping address",
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle form submission
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text("Submit"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
