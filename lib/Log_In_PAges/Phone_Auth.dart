import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'Otp_Screen.dart';

class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({super.key});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  bool _agreedToPolicy = false;
  bool _isLoading = false;

  void showGifLoader(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Image.asset('assets/images/0s-200px-200px-unscreen.gif'),
        ),
      ),
    );
  }

  void _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToPolicy) {
      Get.snackbar(
        "Agreement",
        "Please agree to the terms",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    showGifLoader(context);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91${_phoneController.text.trim()}",
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          if (Navigator.canPop(context)) Navigator.pop(context);
          print("✅ verificationCompleted");
        },

        verificationFailed: (FirebaseAuthException e) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          setState(() => _isLoading = false);
          print("❌ verificationFailed: ${e.message}");
          Get.snackbar("Verification Failed", e.message ?? 'Error');
        },

        codeSent: (String verificationId, int? resendToken) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          setState(() => _isLoading = false);
          print("📨 codeSent");
          Get.to(
            () => VerificationPage(
              verificationId: verificationId,
              phoneNumber: _phoneController.text.trim(),
            ),
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          setState(() => _isLoading = false);
          print("⏳ Timeout");
          Get.snackbar("Timeout", "OTP auto-retrieval timed out");
        },
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      setState(() => _isLoading = false);
      print("❗ Exception: $e");
      Get.snackbar("Error", "$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
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
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Center(
                        child: Image.asset(
                          "assets/images/chef-removebg-preview.png",
                          height: 200,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                "Welcome Back",
                                style: TextStyle(
                                  fontSize: 40,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              const Text(
                                "Login with your phone",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 30),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.phone),
                                  labelText: 'Phone Number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length < 10) {
                                    return 'Enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _agreedToPolicy,
                                    onChanged: (val) {
                                      setState(() {
                                        _agreedToPolicy = val ?? false;
                                      });
                                    },
                                  ),
                                  const Expanded(
                                    child: Text(
                                      "I agree to Terms and Privacy Policy",
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: const StadiumBorder(),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        'Continue',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
