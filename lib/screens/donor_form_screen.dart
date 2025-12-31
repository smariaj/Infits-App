import 'package:flutter/material.dart';

class RecordDefinitionScreen extends StatefulWidget {
  const RecordDefinitionScreen({super.key});

  @override
  State<RecordDefinitionScreen> createState() => _RecordDefinitionScreenState();
}

class _RecordDefinitionScreenState extends State<RecordDefinitionScreen> {
  DateTime selectedDate = DateTime.now();

  final TextEditingController donorNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController donationAmountController =
  TextEditingController();

  String donorType = 'One Time';
  String paymentType = 'General';
  String paymentMode = 'UPI';

  List<String> donorTypes = ['One Time', 'Regular', 'Other'];
  List<String> paymentTypes = ['General', 'Special', 'Other'];
  List<String> paymentModes = ['UPI', 'Cash', 'Cheque'];

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
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
        leading: const BackButton(),
        title: const Text("Record Definition"),
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Donor Details Header
            Row(
              children: const [
                Icon(Icons.person, size: 30, color: Colors.blue,),
                SizedBox(width: 8),
                Text(
                  "Donor Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.grey),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Date and Telecaller
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Date"),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                              border:
                              Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(
                              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Telecaller"),
                      SizedBox(height: 4),
                      TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: "John Doe",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

            // Mobile No & Location
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Mobile No"),
                      const SizedBox(height: 4),
                      TextField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Enter mobile no",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Location"),
                      const SizedBox(height: 4),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Enter location",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type of Donor
            const Text("Type of Donor"),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: donorType,
              items: donorTypes
                  .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => donorType = value);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Section
            Row(
              children: const [
                Icon(Icons.money, size: 30, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "Payment",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.grey),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Donation Amount
            const Text("Donation Amount"),
            const SizedBox(height: 4),
            TextField(
              controller: donationAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter amount",
              ),
            ),
            const SizedBox(height: 16),

            // Type & Mode
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Type"),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: paymentType,
                        items: paymentTypes
                            .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => paymentType = value);
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Mode"),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: paymentMode,
                        items: paymentModes
                            .map((mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(mode),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => paymentMode = value);
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                  backgroundColor: Colors.blue, // Button background color
                  foregroundColor: Colors.white, // Text & icon color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
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
