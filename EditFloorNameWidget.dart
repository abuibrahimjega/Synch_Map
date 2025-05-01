import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'DBConnection.dart';
import 'Login.dart';
import './ApiService.dart'; // Import the ApiService

class EditFloorNameWidget extends StatefulWidget {
  const EditFloorNameWidget({super.key});

  @override
  State<EditFloorNameWidget> createState() => _EditFloorNameWidgetState();
}

class _EditFloorNameWidgetState extends State<EditFloorNameWidget> {
  final TextEditingController _mapIdController = TextEditingController();
  final TextEditingController _floorIdController = TextEditingController();
  final TextEditingController _newFloorNameController = TextEditingController();
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
      // Apply text removal to the selected image first
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
    final floorId = int.tryParse(_floorIdController.text.trim());
    final newFloorName = _newFloorNameController.text.trim();

    if (mapId == null || floorId == null) {
      setState(() => _message = 'Please fill Map ID and Floor ID');
      return;
    }

    if (newFloorName.isEmpty && _selectedImage == null) {
      setState(() => _message = 'Please provide new name or image');
      return;
    }

    final isAdmin = await DBConnection.isUserAdmin(userId);
    final isOwner = await DBConnection.isUserMapOwner(userId, mapId);

    if (!(isAdmin || isOwner)) {
      setState(
          () => _message = 'You do not have permission to edit this floor.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imagePath;
      if (_selectedImage != null) {
        imagePath = await _uploadImage();
        if (imagePath == null) throw Exception('Image upload failed');
      }

      final success = await DBConnection.editFloorInfo(
        floorId: floorId,
        mapId: mapId,
        newFloorName: newFloorName.isEmpty ? null : newFloorName,
        newImagePath: imagePath,
      );

      setState(() {
        _message = success
            ? 'Floor updated successfully!'
            : 'Failed to update floor. Please try again.';
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
      appBar: AppBar(
        title: const Text('Edit Floor Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              controller: _floorIdController,
              decoration: const InputDecoration(
                labelText: 'Floor ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newFloorNameController,
              decoration: const InputDecoration(
                labelText: 'New Floor Name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessingImage ? null : _pickImage,
              child: Text(_selectedImage == null
                  ? 'Select New Floor Image (optional)'
                  : 'New Image Selected'),
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
                    child: const Text('Update Floor'),
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapIdController.dispose();
    _floorIdController.dispose();
    _newFloorNameController.dispose();
    super.dispose();
  }
}
