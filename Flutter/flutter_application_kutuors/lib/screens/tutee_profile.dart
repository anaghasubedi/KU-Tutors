import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TuteeProfilePage extends StatefulWidget {
  final bool isPrivateView; // true: user editing own profile, false: public view
  const TuteeProfilePage({super.key, this.isPrivateView = true});

  @override
  State<TuteeProfilePage> createState() => _TuteeProfilePageState();
}

class _TuteeProfilePageState extends State<TuteeProfilePage> {
  Uint8List? _imageBytes;

  final TextEditingController _nameController =
      TextEditingController(text: "Jane Smith");
  final TextEditingController _kuEmailController =
      TextEditingController(text: "jane.smith@ku.edu.np");
  final TextEditingController _phoneController =
      TextEditingController(text: "+977 9812345678");
  final TextEditingController _departmentController =
      TextEditingController(text: "Business Administration");

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
        // TODO: Upload _imageBytes to your database/server
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

  void _saveProfile() {
    // TODO: Implement save logic (upload to database)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }

  void _deleteAccount() {
    // TODO: Implement delete account logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A7AB8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'Tutee Profile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

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
                      _buildEditableField('KU Email', _kuEmailController),
                      const SizedBox(height: 12),
                      _buildEditableField('Phone no', _phoneController),
                      const SizedBox(height: 12),
                      _buildEditableField('Department', _departmentController),
                      const SizedBox(height: 32),

                      if (widget.isPrivateView) ...[
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A7AB8),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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
                              backgroundColor: const Color(0xFF4A7AB8),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildEditableField(String label, TextEditingController controller) {
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
          child: widget.isPrivateView
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
}
