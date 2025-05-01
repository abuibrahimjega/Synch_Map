import 'dart:io';
import 'package:flutter/material.dart';
import 'EditMap.dart';
import 'DBConnection.dart';
import 'Login.dart';

class AddMap extends StatefulWidget {
  const AddMap({super.key});

  @override
  State<AddMap> createState() => _AddMapState();
}

class _AddMapState extends State<AddMap> {
  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _locationUrlController = TextEditingController();

  // File? _imageFile; // To store the selected image file
  String _message = ''; // To display success or error messages

  // Handle form submission
  Future<void> _submitForm() async {
    final userId = Login.getCurrentUserId();
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    final type = _typeController.text.trim();
    final locationUrl = _locationUrlController.text.trim();

    if (userId == null) {
      setState(() {
        _message = 'User ID not found. Please log in again.';
      });
      return;
    }

    if (name.isEmpty || city.isEmpty || type.isEmpty || locationUrl.isEmpty) {
      setState(() {
        _message = 'Please fill all fields and select an image.';
      });
      return;
    }

    try {
      final imagePath = '';
      final result = await DBConnection.addMap(
        UID: userId,
        MName: name,
        MCity: city,
        MType: type,
        MLocationURL: locationUrl,
        MImage: imagePath,
      );

      setState(() {
        _message = result
            ? 'Map added successfully!'
            : 'Failed to add map. Please try again.';
      });
    } catch (e) {
      setState(() {
        _message = 'An error occurred. Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Map')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Map Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                  labelText: 'City', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                  labelText: 'Type', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationUrlController,
              decoration: const InputDecoration(
                  labelText: 'Location URL', border: OutlineInputBorder()),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submitForm, child: const Text('Submit')),
            const SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(
                  color: _message.contains('successfully')
                      ? Colors.blue
                      : Colors.red),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditMapInfo()),
                );
              },
              child: const Text('Edit Map Info'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _typeController.dispose();
    _locationUrlController.dispose();
    super.dispose();
  }
}
