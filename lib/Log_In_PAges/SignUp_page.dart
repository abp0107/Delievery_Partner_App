import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../personal_information_pages/opload_documents.dart';

class SignupPage extends StatefulWidget {
  final String uid;
  const SignupPage({super.key, required this.uid});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  late AnimationController _controller;
  late Animation<Offset> _snackAnimation;
  bool _isSnackVisible = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _snackAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    fetchExistingData(); // fetch if already registered
  }

  Future<void> fetchExistingData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('delivery_boys')
        .doc(currentUser.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      setState(() {
        _fullNameController.text = data['FullName'] ?? '';
        _mobileController.text = data['MobileNumber'] ?? '';
        _addressController.text = data['Address'] ?? '';
        _landmarkController.text = data['Landmark'] ?? '';
        _pincodeController.text = data['Pincode'] ?? '';
      });
    }
  }

  Future<void> _submitForm() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar(
        "Error",
        "User not logged in.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final uid = currentUser.uid;

        await FirebaseFirestore.instance
            .collection('delivery_boys')
            .doc(uid)
            .set({
              'FullName': _fullNameController.text.trim(),
              'MobileNumber': _mobileController.text.trim(),
              'Address': _addressController.text.trim(),
              'Landmark': _landmarkController.text.trim(),
              'Pincode': _pincodeController.text.trim(),
              'isUsingApp': true,
              'isFavourite': false,
              'uid': uid,
              'createdAt': FieldValue.serverTimestamp(),
            });

        Get.snackbar(
          "Success",
          "Registration completed!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );

        await Future.delayed(const Duration(seconds: 1));
        Get.offAll(() => const PersonalDocumentsPage());
      } catch (e) {
        Get.snackbar(
          "Error",
          "Something went wrong: $e",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }

      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fullNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    super.dispose();
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
            child: Column(
              children: [
                const SizedBox(height: 47),
                Center(
                  child: Image.asset(
                    "assets/images/signup_page.png",
                    height: 300,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 180),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
                        Text(
                          "Create An Account",
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _fullNameController,
                          label: "Full Name",
                          icon: Icons.person,
                          capitalization: TextCapitalization.words,
                          validator: (value) =>
                              value!.isEmpty ? "Enter full name" : null,
                        ),
                        const SizedBox(height: 15),
                        _buildField(
                          controller: _mobileController,
                          label: "Mobile Number",
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          validator: (value) {
                            if (value!.isEmpty) return 'Enter mobile number';
                            if (value.length != 10) {
                              return 'Enter valid 10-digit number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildField(
                          controller: _addressController,
                          label: "Address",
                          icon: Icons.home,
                          capitalization: TextCapitalization.sentences,
                          validator: (value) =>
                              value!.isEmpty ? "Enter address" : null,
                        ),
                        const SizedBox(height: 15),
                        _buildField(
                          controller: _landmarkController,
                          label: "Landmark",
                          icon: Icons.location_on,
                          capitalization: TextCapitalization.sentences,
                          validator: (value) =>
                              value!.isEmpty ? "Enter landmark" : null,
                        ),
                        const SizedBox(height: 15),
                        _buildField(
                          controller: _pincodeController,
                          label: "Pincode",
                          icon: Icons.pin,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          validator: (value) {
                            if (value!.isEmpty) return 'Enter pincode';
                            if (value.length != 6) {
                              return 'Enter 6-digit pincode';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Register',
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      maxLength: maxLength,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(icon),
        counterText: "",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
