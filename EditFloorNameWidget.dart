import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../DBConnection.dart';
import '../Login.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

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

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _processImage() async {
    if (_selectedImage == null) return null;

    const serverUrl = 'http://192.168.1.14:5000/remove-text';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(serverUrl));
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _selectedImage!.path,
        filename: basename(_selectedImage!.path),
      ));
      
      // Add required parameters for text removal
      request.fields['languages'] = 'en';
      request.fields['inpaint_radius'] = '3';

      var response = await request.send();
      
      if (response.statusCode == 200) {
        // Save processed image locally
        final bytes = await response.stream.toBytes();
        final String localPath = '${_selectedImage!.path}_processed.jpg';
        await File(localPath).writeAsBytes(bytes);
        return localPath;
      }
      return null;
    } catch (e) {
      print('Processing error: $e');
      return null;
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
      setState(() => _message = 'You do not have permission to edit this floor.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imagePath;
      if (_selectedImage != null) {
        imagePath = await _processImage();
        if (imagePath == null) throw Exception('Image processing failed');
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
              onPressed: _pickImage,
              child: Text(_selectedImage == null
                  ? 'Select New Floor Image (optional)'
                  : 'New Image Selected'),
            ),
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 100),
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
