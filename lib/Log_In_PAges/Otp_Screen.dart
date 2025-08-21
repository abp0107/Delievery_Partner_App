import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Home_page.dart';
import '../personal_information_pages/document_stauts.dart';
import 'SignUp_page.dart';

class VerificationPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const VerificationPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showLoader(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  Future<void> verifyOtp() async {
    _showLoader(true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final uid = user.uid;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool("isLoggedIn", true);

        // ✅ Step 1: Check in correct collection
        final userDoc = await FirebaseFirestore.instance
            .collection('delivery_boys')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();

          if (data != null &&
              data.containsKey('FullName') &&
              data.containsKey('MobileNumber')) {
            // ✅ Step 2: Check document status
            final statusDoc = await FirebaseFirestore.instance
                .collection('delivery_boys')
                .doc(uid)
                .collection('documents')
                .doc('status')
                .get();

            if (statusDoc.exists) {
              final statusData = statusDoc.data();

              if (statusData != null &&
                  statusData['aadhar'] == 'Accepted' &&
                  statusData['pan'] == 'Accepted' &&
                  statusData['license'] == 'Accepted') {
                _showLoader(false);
                Get.offAll(() => const OrdersPage());
              } else {
                _showLoader(false);
                Get.offAll(() => const DocumentsStatusPage());
              }
            } else {
              _showLoader(false);
              Get.offAll(() => const DocumentsStatusPage());
            }
          } else {
            _showLoader(false);
            Get.offAll(() => SignupPage(uid: uid)); // partial data
          }
        } else {
          _showLoader(false);
          Get.offAll(() => SignupPage(uid: uid)); // new user
        }
      } else {
        _showLoader(false);
        _showError("User sign-in failed");
      }
    } catch (e) {
      _showLoader(false);
      _showError("OTP Verification failed: ${e.toString()}");
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/splashscreen.png",
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SizedBox.expand(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    Image.asset(
                      "assets/images/chef-removebg-preview.png",
                      height: 200,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "OTP Verification",
                      style: TextStyle(
                        fontSize: 38,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Enter your 6-digit code sent to your number",
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                counterText: "",
                                prefixIcon: const Icon(Icons.lock),
                                labelText: 'Enter OTP',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  "Verify OTP",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Image.asset(
                  "assets/images/0s-200px-200px-unscreen.gif",
                  width: 100,
                  height: 100,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
