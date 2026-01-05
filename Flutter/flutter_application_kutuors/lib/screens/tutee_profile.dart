import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TuteeProfilePage extends StatefulWidget {
  final bool isPrivateView; // true: user editing own profile, false: public view
  const TuteeProfilePage({super.key, this.isPrivateView = true});

  @override
  State<TuteeProfilePage> createState() => _TuteeProfilePageState();
}

class _TuteeProfilePageState extends State<TuteeProfilePage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _token;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _kuEmailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _subjectRequiredController = TextEditingController();

  // API Base URL - Update this to match your backend
  static const String baseUrl = 'http://10.0.2.2:8000'; // Use 10.0.2.2 for Android emulator, localhost for iOS

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');

      if (_token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/update-profile/'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          _nameController.text = data['name'] ?? '';
          _kuEmailController.text = data['email'] ?? '';
          _phoneController.text = data['phone_number'] ?? '';
          _semesterController.text = data['semester'] ?? '';
          _subjectRequiredController.text = data['subject_required'] ?? '';
          _isLoading = false;
        });

        // Load profile picture if available
        // You'll need to add this endpoint to your backend
        // await _loadProfilePicture();
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });

        // Upload image to backend
        await _uploadImage(pickedFile);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    }
  }

  Future<void> _uploadImage(XFile imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload-image/'),
      );
      
      request.headers['Authorization'] = 'Token $token';
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));

      final response = await request.send();
      
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully')),
          );
        }
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/update-profile/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text,
          'phone_number': _phoneController.text,
          'semester': _semesterController.text,
          'subject_required': _subjectRequiredController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully')),
          );
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to save profile');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/delete-account/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Clear stored data
        await prefs.clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
          
          // Navigate to login page
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        throw Exception('Failed to delete account');
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF4A7AB8),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

return Scaffold(
  backgroundColor: const Color(0xFF4A7AB8),
  appBar: AppBar(
    backgroundColor: const Color(0xFF4A7AB8),
    elevation: 0,
    automaticallyImplyLeading: false,
    title: const Text(
      'Tutee Profile',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    centerTitle: true,
  ),
  body: SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8BA3C7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: widget.isPrivateView ? _pickImage : null,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            image: _imageBytes != null
                                ? DecorationImage(
                                    image: MemoryImage(_imageBytes!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _imageBytes == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'PHOTO',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tap to upload',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                )
                              : widget.isPrivateView
                                  ? Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.black.withValues(alpha: 0.3),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                    )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildEditableField('Name', _nameController),
                      const SizedBox(height: 12),
                      _buildEditableField('KU Email', _kuEmailController, enabled: false),
                      const SizedBox(height: 12),
                      _buildEditableField('Phone no', _phoneController),
                      const SizedBox(height: 12),
                      _buildEditableField('Semester', _semesterController),
                      const SizedBox(height: 12),
                      _buildEditableField('Subject Required', _subjectRequiredController),
                      const SizedBox(height: 32),

                      if (widget.isPrivateView) ...[
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A7AB8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _saveProfile,
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Delete Account Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _deleteAccount,
                            child: const Text(
                              'Delete Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {bool enabled = true}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label :',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: widget.isPrivateView && enabled
              ? TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                  ),
                )
              : Text(
                  controller.text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kuEmailController.dispose();
    _phoneController.dispose();
    _semesterController.dispose();
    _subjectRequiredController.dispose();
    super.dispose();
  }
}