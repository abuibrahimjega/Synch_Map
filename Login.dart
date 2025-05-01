import 'package:flutter/material.dart';
import 'package:myfirst/AddUser.dart';
import 'DBConnection.dart';

class Login {
  static Map<String, dynamic>? currentUser;

  static Future<bool> logIn(int ID, String password) async {
    try {
      final user = await DBConnection.logInByID(ID, password);

      if (user != null) {
        currentUser = user;
        return true;
      } else {
        currentUser = null;
        return false;
      }
    } catch (e) {
      print('Error during login: $e');
      currentUser = null;
      return false;
    }
  }

  static String? getCurrentUserName() {
    return currentUser?['UName'];
  }

  static int? getCurrentUserId() {
    final uid = currentUser?['UID'];
    return uid is String ? int.tryParse(uid) : uid as int?;
  }

  static int? getCurrentUserIsAdmin() {
    final uIsAdmin = currentUser?['UIsAdmin'];
    return uIsAdmin is String ? int.tryParse(uIsAdmin) : uIsAdmin as int?;
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    DBConnection.initialize();
  }

  Future<void> _login() async {
    final uid = int.tryParse(_uidController.text.trim());
    final pass = _passController.text.trim();

    if (uid == null || pass.isEmpty) {
      setState(() {
        _errorMessage = 'Wrong ID or Empty passwords';
      });
      return;
    }

    try {
      final isLoggedIn = await Login.logIn(uid, pass);
      if (isLoggedIn) {
        print('\n\n\ngggggggggggg\n\n\n');

        setState(() {
          _errorMessage = 'correct';
        });
        // here we may go to home screen
      } else {
        setState(() {
          _errorMessage = 'wrong';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _uidController,
              decoration: InputDecoration(
                labelText: 'Enter UID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _passController,
              decoration: InputDecoration(
                labelText: 'Enter Password',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.visiblePassword,
            ),
            SizedBox(height: 20),
            if (_errorMessage == 'correct')
              Text(
                'User Logged In',
                style: TextStyle(color: Colors.blue),
              ),
            if (_errorMessage == 'wrong')
              Text(
                'User not Exist',
                style: TextStyle(color: Colors.red),
              ),
            if (_errorMessage.isEmpty)
              Text(
                '...',
                style: TextStyle(color: Colors.black),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserAccount()),
                );
              },
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }
}
