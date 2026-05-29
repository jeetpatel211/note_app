import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String localIp = "http://192.168.0.107:5000";
  static const String baseUrl = "$localIp/api";

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {"success": true, "message": data['message']};
      } else {
        // Try parsing JSON, fallback to raw body
        try {
          final data = jsonDecode(response.body);
          return {
            "success": false,
            "message": data["message"] ?? "Unknown error",
          };
        } catch (_) {
          return {"success": false, "message": response.body};
        }
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),

        headers: {"Content-Type": "application/json"},

        body: jsonEncode({"email": email, "password": password}),
      );

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          "success": true,
          "message": data["message"],
          "token": data["token"],
          "user": data["user"],
        };
      } else {
        final data = jsonDecode(response.body);

        return {"success": false, "message": data["message"]};
      }
    } catch (e) {
      print(e);

      return {"success": false, "message": "Network Error : $e"};
    }
  }

  static Future<Map<String, dynamic>> googleLogin({
    required String name,
    required String email,
    required String googleId,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/google-login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "googleId": googleId}),
    );

    return jsonDecode(response.body);
  }
}
