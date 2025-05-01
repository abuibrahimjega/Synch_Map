import 'package:flutter/material.dart';
import 'DBConnection.dart'; // Import the DBConnection class
import 'Login.dart'; // Import the Login class

class EditUserInfo extends StatefulWidget {
  const EditUserInfo({super.key});

  @override
  State<EditUserInfo> createState() => _EditUserInfoState();
}

class _EditUserInfoState extends State<EditUserInfo> {
  // Controllers for the text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _message = ''; // To display success or error messages

  // Method to handle form submission
  Future<void> _submitChanges() async {
    final userId = Login.getCurrentUserId(); // Get the logged-in user's ID
    final newName = _nameController.text.trim();
    final newPassword = _passwordController.text.trim();
    final newEmail = _emailController.text.trim();

    if (userId == null) {
      setState(() {
        _message = 'User ID not found. Please log in again.';
      });
      return;
    }

    try {
      bool success = true;

      // Update name if the field is not empty
      if (newName.isNotEmpty) {
        final result = await DBConnection.changeName(userId, newName);
        if (!result) {
          success = false;
        }
      }

      print('\n\nBefore if pass not empty\n\n\n');
      // Update password if the field is not empty
      if (newPassword.isNotEmpty) {
        final result = await DBConnection.changePass(userId, newPassword);
        print('\n\n\n Inside if pass not empty\n\n\n');
        if (!result) {
          print('\n\n\n False result \n\n\n\n\n\n\n\n');
          success = false;
        }
      }

      // Update email if the field is not empty
      if (newEmail.isNotEmpty) {
        final result = await DBConnection.changeEmail(userId, newEmail);
        if (!result) {
          success = false;
        }
      }

      // Display success or failure message
      setState(() {
        _message = success
            ? 'User information updated successfully!'
            : 'Failed to update some fields. Please try again.';
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _message = 'An error occurred. Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'New Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'New Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitChanges,
              child: const Text('Submit Changes'),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(
                color: _message.contains('successfully')
                    ? Colors.green
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
