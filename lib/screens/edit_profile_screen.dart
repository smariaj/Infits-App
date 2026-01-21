import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

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

    _fullNameController =
        TextEditingController(text: widget.userData['fullName']);
    _usernameController =
        TextEditingController(text: widget.userData['username']);
    _emailController =
        TextEditingController(text: widget.userData['email']);
    _mobileController =
        TextEditingController(text: widget.userData['mobile']);
    _employeeIdController =
        TextEditingController(text: widget.userData['employeeId']);
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
      imageQuality: 70,
      maxWidth: 400,
      maxHeight: 400,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // ================= SAVE CHANGES (FINAL)
  Future<void> _saveChanges() async {
    final userId = widget.userData['id'];

    final uri = Uri.parse(
      "http://10.169.30.216:3000/users/update-user/$userId",
    );

    try {
      final request = http.MultipartRequest("PUT", uri);

      // Backend field names (IMPORTANT)
      request.fields['name'] = _fullNameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['phone'] = _mobileController.text;

      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            _profileImage!.path,
          ),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = json.decode(body);

      if (response.statusCode == 200 && data["success"] == true) {
        // Update SharedPreferences with new data
        final prefs = await SharedPreferences.getInstance();

        // Update name if changed
        if (_fullNameController.text.trim().isNotEmpty) {
          await prefs.setString("user_name", _fullNameController.text.trim());
        }

        // Update profile image if backend returns a new one
        if (data["data"] != null && data["data"]["profile_image"] != null) {
          await prefs.setString("profile_image", data["data"]["profile_image"]);
        } else if (_profileImage != null) {
          // If we uploaded a new image but backend doesn't return filename
          // You might need to handle this differently based on your backend
          // For now, we'll just note that image was updated
          await prefs.setString("profile_image", "updated");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );

        // Return true to indicate successful update
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: ${data["message"] ?? "Unknown error"}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
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
                  child: _profileImage == null &&
                      widget.userData['profileImage'] == null
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
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.userData['fullName'],
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildTextField("Full Name", _fullNameController),
            _buildTextField("Username", _usernameController),
            _buildTextField("Email", _emailController,
                keyboardType: TextInputType.emailAddress),
            _buildTextField("Mobile Number", _mobileController,
                keyboardType: TextInputType.phone),
            _buildTextField("Employee ID", _employeeIdController,
                enabled: false),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                ),
                child:
                const Text("Save Changes", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool enabled = true,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}