import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:notes_app/core/network/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  // Loading

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Token

  String? _token;
  String? get token => _token;

  // User Data

  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  // Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      final response = await ApiService.registerUser(
        name: name,
        email: email,
        password: password,
      );

      // Register Success

      if (response["success"]) {
        _token = response["token"];
        _user = response["user"];
        // Save Data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", response["token"]);
        await prefs.setString("user", jsonEncode(response["user"]));
      }
      return response;
    } catch (e) {
      return {"success": false, "message": e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Login

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      final response = await ApiService.loginUser(
        email: email,
        password: password,
      );

      // Login Success

      if (response["success"]) {
        _token = response["token"];
        _user = response["user"];
        // Save Token & User
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", response["token"]);
        await prefs.setString("user", jsonEncode(response["user"]));
      }

      return response;
    } catch (e) {
      return {"success": false, "message": e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check Login

  Future<bool> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString("token");
    final savedUser = prefs.getString("user");

    if (savedToken != null) {
      _token = savedToken;
      if (savedUser != null) {
        _user = jsonDecode(savedUser);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  //=======================================================
  //Logout
  //=======================================================

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _token = null;
    _user = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      print("Google Sign In Started");
      if (googleUser == null) {
        return {"success": false, "message": "Google Sign In Cancelled"};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user == null) {
        return {"success": false, "message": "User not found"};
      }

      print("Firebase User: ${user.email}");

      final response = await ApiService.googleLogin(
        name: user.displayName ?? "",
        email: user.email ?? "",
        googleId: user.uid,
      );

      print("Backend Response: $response");
      if (response["success"]) {
        _token = response["token"];
        _user = response["user"];

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("token", response["token"]);

        await prefs.setString("user", jsonEncode(response["user"]));
      }

      return response;
    } catch (e) {
      print("Google Sign In Error => $e");
      rethrow;
      // return {"success": false, "message": e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
