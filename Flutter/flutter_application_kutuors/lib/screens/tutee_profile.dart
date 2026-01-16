import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_kutuors/services/service_locator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class TuteeProfilePage extends StatefulWidget {
  final bool isPrivateView;
  const TuteeProfilePage({super.key, this.isPrivateView = true});

  @override
  State<TuteeProfilePage> createState() => _TuteeProfilePageState();
}

class _TuteeProfilePageState extends State<TuteeProfilePage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _kuEmailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Changed to dropdown values
  String? _selectedDepartment;
  String? _selectedYear;
  String? _selectedSemester;

  final List<String> _departments = ['CS', 'CE'];
  final List<String> _years = ['1', '2', '3', '4'];
  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final data = await services.profileService.getProfileData();

      setState(() {
        _nameController.text = data['name'] ?? '';
        _kuEmailController.text = data['email'] ?? '';
        _phoneController.text = data['phone_number'] ?? '';
        
        // Set dropdown values
        _selectedDepartment = data['department'];
        _selectedYear = data['year'];
        _selectedSemester = data['semester'];
        
        _isLoading = false;
      });

      await _loadProfilePicture();
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

  Future<void> _loadProfilePicture() async {
    try {
      final imageData = await services.profileService.getProfileImage();
      
      if (imageData != null) {
        if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
          final response = await http.get(Uri.parse(imageData));
          if (response.statusCode == 200) {
            setState(() {
              _imageBytes = response.bodyBytes;
            });
          }
        } else if (imageData.startsWith('data:image')) {
          final base64String = imageData.split(',').last;
          setState(() {
            _imageBytes = base64Decode(base64String);
          });
        } else {
          setState(() {
            _imageBytes = base64Decode(imageData);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile picture: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });

        await _uploadImage(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      await services.profileService.uploadProfileImage(imageFile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
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
      await services.profileService.updateProfileData(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        department: _selectedDepartment ?? '',
        year: _selectedYear ?? '',
        semester: _selectedSemester ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
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
      await services.profileService.deleteAccount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );

        Navigator.pushReplacementNamed(context, '/login');
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
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
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
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
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
                                      'Add Photo',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : widget.isPrivateView
                                  ? Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
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
                      _buildEditableField(
                        'KU Email',
                        _kuEmailController,
                        enabled: false,
                      ),
                      const SizedBox(height: 22),
                      _buildEditableField('Phone no', _phoneController),
                      const SizedBox(height: 12),
                      
                      // Department Dropdown
                      _buildDropdownField('Department', _selectedDepartment, _departments, (value) {
                        setState(() {
                          _selectedDepartment = value;
                        });
                      }),
                      const SizedBox(height: 12),
                      
                      // Year Dropdown
                      _buildDropdownField('Year', _selectedYear, _years, (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      }),
                      const SizedBox(height: 12),
                      
                      // Semester Dropdown
                      _buildDropdownField('Semester', _selectedSemester, _semesters, (value) {
                        setState(() {
                          _selectedSemester = value;
                        });
                      }),
                      const SizedBox(height: 32),

                      if (widget.isPrivateView) ...[
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

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
  }) {
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
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
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

  Widget _buildDropdownField(
    String label,
    String? selectedValue,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
          child: widget.isPrivateView
              ? DropdownButtonFormField<String>(
                  value: selectedValue,
                  dropdownColor: const Color(0xFF8BA3C7),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  items: options.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: onChanged,
                )
              : Text(
                  selectedValue ?? '',
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
    super.dispose();
  }
}