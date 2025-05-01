import 'package:flutter/material.dart';


class User {
  int? UID;
  String? UName;
  String? UHashPass;
  bool? UIsAdmin;

  static final User _instance = User._internal();

  factory User() {
    return _instance;
  }

  User._internal();


  void updateUserData({
    int? uid,
    String? uname,
    String? uHashPass,
    bool? uIsAdmin,
  }) {
    UID = uid;
    UName = uname;
    UHashPass = uHashPass;
    UIsAdmin = uIsAdmin;
  }

}


class UserProvider with ChangeNotifier {
  int? _UID;
  String? _UName;
  String? _UHashPass;
  bool? _UIsAdmin;

  // Getters
  int? get UID => _UID;
  String? get UName => _UName;
  bool? get UIsAdmin => _UIsAdmin;

  // Setters
  void setUser(int? uid, String? uname, bool? isAdmin) {
    _UID = uid;
    _UName = uname;
    _UIsAdmin = isAdmin;
    notifyListeners(); // Notify listeners of the state change
  }
}