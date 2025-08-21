import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../personal_information_pages/document_stauts.dart';
import 'Phone_Auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool showText1 = false;
  bool showText2 = false;
  bool showArrow = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => showText1 = true);

    await Future.delayed(const Duration(seconds: 1));
    setState(() => showText2 = true);

    await Future.delayed(const Duration(seconds: 1));
    setState(() => showArrow = true);

    await Future.delayed(const Duration(seconds: 1));

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final uid = currentUser.uid;

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('delivery_boys')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          final fullName = userDoc['FullName'] ?? 'Delivery Boy';
          Get.to(() => DocumentsStatusPage());
        } else {
          Get.to(() => PhoneInputPage());
        }
      } catch (e) {
        print("❌ Error fetching delivery boy profile: $e");
        Get.snackbar(
          "Error",
          "Failed to load profile.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.to(() => PhoneInputPage());
      }
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => PhoneInputPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3EC37F),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.75,
              child: Image.asset(
                "assets/images/splashscreen.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 325),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: showText1 ? 1.0 : 0.0,
                  child: Text(
                    'Deliver orders with speed & accuracy',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: showText2 ? 1.0 : 0.0,
                  child: Text(
                    'Your journey\nstarts here!',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: showArrow ? 1.0 : 0.0,
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Text(
                        'View Assigned Orders',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Image.asset(
                        "assets/images/aero.png",
                        height: 75,
                        width: 75,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
