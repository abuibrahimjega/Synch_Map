import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import './EditFloorNameWidget.dart';
import 'DBConnection.dart';
import 'Login.dart';
import './ApiService.dart'; // Import the ApiService

class AddFloorWidget extends StatefulWidget {
  const AddFloorWidget({super.key});

  @override
  State<AddFloorWidget> createState() => _AddFloorWidgetState();
}

class _AddFloorWidgetState extends State<AddFloorWidget> {
  final TextEditingController _mapIdController = TextEditingController();
  final TextEditingController _floorNameController = TextEditingController();
  File? _selectedImage;
  String _message = '';
  bool _isLoading = false;
  bool _isProcessingImage = false;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    setState(() => _isProcessingImage = true);

    try {
      // First apply text removal to the selected image
      final processedImage =
          await ApiService.removeTextFromImage(_selectedImage!);

      // Use the processed image if available, otherwise use the original
      final imageToUpload = processedImage ?? _selectedImage!;

      // Upload the image (processed or original)
      return await ApiService.uploadImage(imageToUpload);
    } catch (e) {
      print('Upload error: $e');
      return null;
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  Future<void> _submitForm() async {
    final userId = Login.getCurrentUserId();
    if (userId == null) {
      setState(() => _message = 'User ID not found. Please log in again.');
      return;
    }

    final mapId = int.tryParse(_mapIdController.text.trim());
    final floorName = _floorNameController.text.trim();

    if (mapId == null || floorName.isEmpty) {
      setState(() => _message = 'Please fill all fields.');
      return;
    }

    if (_selectedImage == null) {
      setState(() => _message = 'Please select an image');
      return;
    }

    final isAdmin = await DBConnection.isUserAdmin(userId);
    final isOwner = await DBConnection.isUserMapOwner(userId, mapId);

    if (!(isAdmin || isOwner)) {
      setState(() =>
          _message = 'You do not have permission to add a floor to this map.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image with text removal
      final imagePath = await _uploadImage();
      if (imagePath == null) throw Exception('Image upload failed');

      // Then add floor with image path
      final isFloorAdded =
          await DBConnection.addFloor(mapId, floorName, imagePath);

      setState(() {
        _message =
            isFloorAdded ? 'Floor added successfully!' : 'Failed to add floor';
      });
    } catch (e) {
      setState(() => _message = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Floor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _mapIdController,
              decoration: const InputDecoration(
                labelText: 'Map ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _floorNameController,
              decoration: const InputDecoration(
                labelText: 'Floor Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessingImage ? null : _pickImage,
              child: Text(_selectedImage == null
                  ? 'Select Floor Image'
                  : 'Image Selected'),
            ),
            if (_selectedImage != null)
              Column(
                children: [
                  const SizedBox(height: 10),
                  _isProcessingImage
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : Image.file(_selectedImage!, height: 100),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: Text in the image will be automatically removed',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Add Floor'),
                  ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(
                color: _message.contains('successfully')
                    ? Colors.blue
                    : Colors.red,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: const Text('Go to Log In Page'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditFloorNameWidget()),
                );
              },
              child: const Text('Edit Floor Info'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapIdController.dispose();
    _floorNameController.dispose();
    super.dispose();
  }
}
