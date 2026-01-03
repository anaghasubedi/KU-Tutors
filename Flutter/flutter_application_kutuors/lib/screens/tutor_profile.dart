import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class TutorProfilePage extends StatefulWidget {
  final bool isOwner; // true: tutor viewing their own profile (private), false: public view

  const TutorProfilePage({super.key, this.isOwner = true});

  @override
  State<TutorProfilePage> createState() => _TutorProfilePageState();
}

class _TutorProfilePageState extends State<TutorProfilePage> {
  Uint8List? _imageBytes;

  // Sample data controllers
  final TextEditingController _nameController =
      TextEditingController(text: "Amit Sharma");
  final TextEditingController _kuEmailController =
      TextEditingController(text: "amit.sharma@ku.edu.np");
  final TextEditingController _phoneController =
      TextEditingController(text: "+977 9812345678");
  final TextEditingController _subjectYearController =
      TextEditingController(text: "Physics, 3rd Year");
  final TextEditingController _rateController =
      TextEditingController(text: "Rs. 2000/hr");

  final List<String> _subjects = ["Physics", "Mathematics", "Chemistry"];
  final List<Map<String, String>> _availability = [
    {"day": "Monday", "time": "2 PM - 3 PM", "status": "Available"},
    {"day": "Tuesday", "time": "1 PM - 2 PM", "status": "Booked"},
    {"day": "Wednesday", "time": "3 PM - 4 PM", "status": "Available"},
  ];

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
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

  void _deleteAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account deleted")),
    );
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile saved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A7AB8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A7AB8),
        title: Text(widget.isOwner ? "My Profile" : "Tutor Profile"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ---------------- Tutor Info Card ----------------
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF8BA3C7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // Profile Picture
                    GestureDetector(
                      onTap: widget.isOwner ? _pickImage : null,
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
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.isOwner
                                        ? Icons.add_a_photo
                                        : Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  if (widget.isOwner)
                                    const SizedBox(height: 4),
                                  if (widget.isOwner)
                                    const Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              )
                            : widget.isOwner
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
                    const SizedBox(height: 16),

                    _buildEditableField("Name", _nameController),
                    const SizedBox(height: 12),
                    _buildEditableField("KU Email", _kuEmailController),
                    const SizedBox(height: 12),
                    _buildEditableField("Phone No", _phoneController),
                    const SizedBox(height: 12),
                    _buildEditableField("Subject & Year", _subjectYearController),
                    const SizedBox(height: 12),
                    _buildEditableField("Rate", _rateController),
                    const SizedBox(height: 24),

                    // Save button for private view
                    if (widget.isOwner)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A7AB8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            "Save Profile",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- Subjects ----------------
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Subjects",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _subjects
                    .map(
                      (sub) => Chip(
                        label: Text(sub),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 20),

              // ---------------- Availability ----------------
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Availability",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: _availability.map((slot) {
                  final isAvailable = slot["status"] == "Available";
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text("${slot["day"]} | ${slot["time"]}"),
                      trailing: widget.isOwner
                          ? Text(
                              slot["status"]!,
                              style: TextStyle(
                                  color: isAvailable
                                      ? Colors.green
                                      : Colors.red),
                            )
                          : isAvailable
                              ? ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Booked demo on ${slot["day"]}")),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A7AB8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text(
                                    "Book Demo",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                )
                              : const Text("Booked"),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ---------------- Delete / Logout buttons ----------------
              if (widget.isOwner) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A7AB8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text("Delete Account"),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
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
          width: 120,
          child: Text(
            "$label :",
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        Expanded(
          child: widget.isOwner
              ? TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                  ),
                )
              : Text(
                  controller.text,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
        ),
      ],
    );
  }
}