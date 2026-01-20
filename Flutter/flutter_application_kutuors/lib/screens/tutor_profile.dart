import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_kutuors/services/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class TutorProfilePage extends StatefulWidget {
  final bool isOwner;
  final int? tutorId;

  const TutorProfilePage({super.key, this.isOwner = true, this.tutorId});

  @override
  State<TutorProfilePage> createState() => _TutorProfilePageState();
}

class _TutorProfilePageState extends State<TutorProfilePage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _isOnline = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _kuEmailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedYear;
  String? _selectedSemester;

  final List<String> _departments = ['Computer Science', 'Computer Engineering'];
  final List<String> _years = ['1', '2', '3', '4'];
  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];

  List<String> _subjects = [];
  List<Map<String, dynamic>> _availability = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadAvailability();
    _loadOnlineStatus();
  }

  Future<void> _loadOnlineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isOnline = prefs.getBool('is_online') ?? true;
    });
  }

  Future<void> _toggleOnlineStatus() async {
    final newStatus = !_isOnline;
    
    try {
      await services.profileService.updateProfileData(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        subject: _subjectController.text,
        department: _selectedDepartment ?? '',
        year: _selectedYear ?? '',
        semester: _selectedSemester ?? '',
        rate: _rateController.text,
        accountNumber: _accountNumberController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isOnline = newStatus;
      });
      await prefs.setBool('is_online', newStatus);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'You are now online' : 'You are now offline'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating online status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  String _safeGetString(dynamic value, {String defaultValue = ''}) {
    if (value == null || value == 'null' || value == 'Not Specified' || value == 'Not Provided' || value == 'Unknown') {
      return defaultValue;
    }
    return value.toString();
  }

Future<void> _loadUserProfile() async {
  setState(() => _isLoading = true);

  try {
    Map<String, dynamic> data;
    
    if (widget.isOwner) {
      // Load own profile
      data = await services.profileService.getProfileData();
      
      debugPrint('Owner profile data: $data');
      
      // Update controllers with data
      _nameController.text = _safeGetString(data['name']);
      _kuEmailController.text = _safeGetString(data['email']);
      _phoneController.text = _safeGetString(data['phone_number']);
      _subjectController.text = _safeGetString(data['subject']);
      _rateController.text = _safeGetString(data['rate']);
      _accountNumberController.text = _safeGetString(data['account_number']);
      
      _selectedDepartment = _safeGetString(data['department']).isEmpty 
          ? null 
          : _safeGetString(data['department']);
      _selectedYear = _safeGetString(data['year']).isEmpty 
          ? null 
          : _safeGetString(data['year']);
      _selectedSemester = _safeGetString(data['semester']).isEmpty 
          ? null 
          : _safeGetString(data['semester']);
      
      _isOnline = data['is_online'] ?? true;
      
    } else if (widget.tutorId != null) {
      // Load another tutor's profile
      final response = await services.tutorService.getTutorProfile(widget.tutorId!);
      
      // The response has a 'tutor' key that contains the actual data
      data = response['tutor'] as Map<String, dynamic>;
      
      debugPrint('Public tutor profile data: $data');
      
      // Handle nested user data
      if (data.containsKey('user') && data['user'] != null) {
        final user = data['user'] as Map<String, dynamic>;
        final firstName = _safeGetString(user['first_name']);
        final lastName = _safeGetString(user['last_name']);
        _nameController.text = '$firstName $lastName'.trim();
        _kuEmailController.text = _safeGetString(user['email']);
        _phoneController.text = _safeGetString(user['contact']);
      }
      
      // Profile fields from tutor profile
      _subjectController.text = _safeGetString(data['subject']);
      _rateController.text = _safeGetString(data['rate']);
      _accountNumberController.text = _safeGetString(data['account_number']);
      
      _selectedDepartment = _safeGetString(data['department']).isEmpty 
          ? null 
          : _safeGetString(data['department']);
      _selectedYear = _safeGetString(data['year']).isEmpty 
          ? null 
          : _safeGetString(data['year']);
      _selectedSemester = _safeGetString(data['semester']).isEmpty 
          ? null 
          : _safeGetString(data['semester']);
      
      _isOnline = data['is_online'] ?? false;
    } else {
      throw Exception('No tutor ID provided for public view');
    }

    // Process subjects
    if (_subjectController.text.isNotEmpty) {
      _subjects = _subjectController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Update state all at once
    setState(() {
      _isLoading = false;
    });

    // Save online status to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_online', _isOnline);
    
    // Load profile picture after updating state
    await _loadProfilePicture();
    
  } catch (e, stackTrace) {
    debugPrint('Error loading profile: $e');
    debugPrint('Stack trace: $stackTrace');
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
      String? imageData;
      
      if (widget.isOwner) {
        imageData = await services.profileService.getProfileImage();
      } else if (widget.tutorId != null) {
        final data = await services.tutorService.getTutorProfile(widget.tutorId!);
        
        // Try multiple possible field names
        imageData = _safeGetString(
          data['profile_picture_url'] ?? 
          data['profile_picture'] ?? 
          data['image_url'] ?? 
          data['image']
        );
      }
      
      if (imageData != null && imageData.isNotEmpty && imageData != 'null') {
        await _processImageData(imageData);
      }
    } catch (e) {
      debugPrint('Error loading profile picture: $e');
    }
  }
  
  Future<void> _processImageData(String imageData) async {
    try {
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
    } catch (e) {
      debugPrint('Error processing image data: $e');
    }
  }

Future<void> _loadAvailability() async {
  try {
    Map<String, dynamic> data;
    
    if (widget.isOwner) {
      data = await services.availabilityService.getAvailability();
    } else if (widget.tutorId != null) {
      data = await services.availabilityService.getTutorAvailability(widget.tutorId!);
    } else {
      return;
    }

    debugPrint('Availability data received: $data');
    
    // The backend returns 'availabilities' key, not 'slots'
    final availabilityList = data['availabilities'] ?? [];
    
    setState(() {
      _availability = List<Map<String, dynamic>>.from(availabilityList);
    });
    
    debugPrint('Availability updated: $_availability');
  } catch (e) {
    debugPrint('Error loading availability: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load availability: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

  Future<void> _showAddAvailabilityDialog() async {
    DateTime? selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Availability'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    selectedDate == null
                        ? 'Select Date'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setDialogState(() => selectedDate = date);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    startTime == null
                        ? 'Select Start Time'
                        : 'Start: ${startTime!.format(context)}',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) setDialogState(() => startTime = time);
                  },
                ),
                ListTile(
                  title: Text(
                    endTime == null
                        ? 'Select End Time'
                        : 'End: ${endTime!.format(context)}',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) setDialogState(() => endTime = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedDate != null && startTime != null && endTime != null) {
                  Navigator.pop(context);
                  await _addAvailability(selectedDate!, startTime!, endTime!);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAvailability(
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final startTimeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

      await services.availabilityService.addAvailability(
        date: dateStr,
        startTime: startTimeStr,
        endTime: endTimeStr,
      );

      await _loadAvailability();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding availability: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAvailability(int id) async {
    try {
      await services.availabilityService.deleteAvailability(id);
      await _loadAvailability();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting availability: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bookDemoSession(int availabilityId) async {
    try {
      await services.tuteeService.bookDemoSession(availabilityId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo session booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await _loadAvailability();
    } catch (e) {
      debugPrint('Error booking demo session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Future<void> _saveProfile() async {
    try {
      await services.profileService.updateProfileData(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        subject: _subjectController.text,
        department: _selectedDepartment ?? '',
        year: _selectedYear ?? '',
        semester: _selectedSemester ?? '',
        rate: _rateController.text,
        accountNumber: _accountNumberController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
      }
      await _loadUserProfile();
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
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
        automaticallyImplyLeading: !widget.isOwner,
        leading: !widget.isOwner 
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          widget.isOwner ? "My Profile" : "Tutor Profile",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.isOwner)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: _toggleOnlineStatus,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha:0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                                    widget.isOwner ? Icons.add_a_photo : Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  if (widget.isOwner) const SizedBox(height: 4),
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
                                      color: Colors.black.withValues(alpha:0.3),
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
                    _buildEditableField("KU Email", _kuEmailController, enabled: false),
                    const SizedBox(height: 12),
                    _buildEditableField("Phone No", _phoneController),
                    const SizedBox(height: 12),
                    _buildEditableField("Subject", _subjectController),
                    const SizedBox(height: 12),
                    _buildDropdownField("Department", _selectedDepartment, _departments, (value) {
                      setState(() => _selectedDepartment = value);
                    }),
                    const SizedBox(height: 12),
                    _buildDropdownField("Year", _selectedYear, _years, (value) {
                      setState(() => _selectedYear = value);
                    }),
                    const SizedBox(height: 12),
                    _buildDropdownField("Semester", _selectedSemester, _semesters, (value) {
                      setState(() => _selectedSemester = value);
                    }),
                    const SizedBox(height: 12),
                    _buildEditableField("Rate", _rateController),
                    const SizedBox(height: 12),
                    _buildEditableField("Account Number", _accountNumberController),
                    const SizedBox(height: 24),

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
                          child: const Text("Save Profile", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_subjects.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Subjects",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
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
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Availability",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.isOwner)
                    ElevatedButton.icon(
                      onPressed: _showAddAvailabilityDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A7AB8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              _availability.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No availability slots added yet',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      children: _availability.map((slot) {
                        final status = slot['status'] ?? 'Available';
                        final isAvailable = status == 'Available';
                        final isBooked = status == 'Booked';
                        final dayName = slot['day_name'] ?? '';
                        final formattedDate = slot['formatted_date'] ?? slot['date'];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text("$dayName, $formattedDate"),
                            subtitle: Text(slot['formatted_time'] ?? ''),
                            trailing: widget.isOwner
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAvailable 
                                              ? Colors.green.withValues(alpha: 0.2)
                                              : isBooked
                                                  ? Colors.blue.withValues(alpha: 0.2)
                                                  : Colors.red.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isAvailable 
                                                ? Colors.green
                                                : isBooked
                                                    ? Colors.blue
                                                    : Colors.red,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: isAvailable 
                                                ? Colors.green
                                                : isBooked
                                                    ? Colors.blue
                                                    : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteAvailability(slot['id']),
                                      ),
                                    ],
                                  )
                                : isAvailable
                                    ? ElevatedButton(
                                        onPressed: () => _bookDemoSession(slot['id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4A7AB8),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                        ),
                                        child: const Text(
                                          "Book",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      )
                                    : isBooked
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4A7AB8).withValues(alpha: 0.5),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              "Booked",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            status,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                            ),
                                          ),
                          ),
                        );
                      }).toList(),
                    ),

              const SizedBox(height: 24),

              if (widget.isOwner) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
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

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            "$label :",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: widget.isOwner && enabled
              ? TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
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
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            "$label :",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: widget.isOwner
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: value,
                      hint: Text(
                        'Select $label',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF4A7AB8),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      items: items.map((String item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: onChanged,
                    ),
                  ),
                )
              : Text(
                  value ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
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
    _subjectController.dispose();
    _rateController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }
}