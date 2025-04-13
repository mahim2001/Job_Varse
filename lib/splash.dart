import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jobvarse_bd/home.dart'; // Replace with your actual home page import

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Optional: change to match your brand
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
      Padding(
        padding: const EdgeInsets.only(top: 100),
          child: Center(
            child: Image.asset(
              'assets/images/JobVarse BD.png',
              width: 400,
              height: 600,
            ),
          ),
      ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(bottom: 30),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Change color if needed
            ),
          ),
        ],
      ),
    );
  }
}
