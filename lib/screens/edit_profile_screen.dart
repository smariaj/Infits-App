import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // Dynamic data from backend

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _employeeIdController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.userData['fullName']);
    _usernameController = TextEditingController(text: widget.userData['username']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _mobileController = TextEditingController(text: widget.userData['mobile']);
    _employeeIdController = TextEditingController(text: widget.userData['employeeId']);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // compress image to 70%
      maxWidth: 400, // resize width
      maxHeight: 400, // resize height
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _saveChanges() async {
    // Collect updated data
    final updatedData = {
      "fullName": _fullNameController.text,
      "username": _usernameController.text,
      "email": _emailController.text,
      "mobile": _mobileController.text,
      "employeeId": _employeeIdController.text,
      "profileImage": _profileImage, // Send File or convert to Base64 for backend
    };

    // TODO: Send `updatedData` to backend using POST/PUT
    // Example using http:
    // var request = http.MultipartRequest('POST', Uri.parse('https://your-backend.com/update-profile'));
    // request.fields['fullName'] = updatedData['fullName'];
    // ... add other fields
    // if (_profileImage != null) {
    //   request.files.add(await http.MultipartFile.fromPath('profileImage', _profileImage!.path));
    // }
    // var response = await request.send();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (widget.userData['profileImage'] != null
                      ? NetworkImage(widget.userData['profileImage'])
                      : null) as ImageProvider<Object>?,
                  child: _profileImage == null && widget.userData['profileImage'] == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.userData['fullName'] ?? "Full Name",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildTextField("Full Name", _fullNameController),
            _buildTextField("Username", _usernameController),
            _buildTextField("Email", _emailController, keyboardType: TextInputType.emailAddress),
            _buildTextField("Mobile Number", _mobileController, keyboardType: TextInputType.phone),
            _buildTextField("Employee ID", _employeeIdController, enabled: false),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                ),
                child: const Text("Save Changes", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = true, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
