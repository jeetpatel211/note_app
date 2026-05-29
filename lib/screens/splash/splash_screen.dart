import 'package:flutter/material.dart';
import 'package:notes_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkUserLogin();
  }

  Future<void> checkUserLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await Future.delayed(Duration(seconds: 2));

    final isLoggedIn = await authProvider.checkLogin();

    if (!mounted) return;

    // Navigate
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }
  // Small Delay

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset("assets/images/Frame_1.png", height: 100, width: 100),
            // Icon(Icons.flutter_dash, size: 90, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              "Material Notes",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            Text(
              "CAPTURE EVERYTHING",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            // Loader
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
