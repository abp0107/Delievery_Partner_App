import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'document_stauts.dart';
import 'upload_Driving_Licaence.dart';
import 'upload_aadhar.dart';
import 'upload_pancard.dart';

class PersonalDocumentsPage extends StatefulWidget {
  const PersonalDocumentsPage({super.key});

  @override
  State<PersonalDocumentsPage> createState() => _PersonalDocumentsPageState();
}

class _PersonalDocumentsPageState extends State<PersonalDocumentsPage> {
  bool isLoading = true;
  bool aadharUploaded = false;
  bool panUploaded = false;
  bool DrUploaded = false;

  @override
  void initState() {
    super.initState();
    fetchUploadStatus();
  }

  Future<void> fetchUploadStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('delivery_boys')
        .doc(uid)
        .get();

    final data = doc.data();
    if (data != null) {
      setState(() {
        aadharUploaded =
            (data['aadharCardFront'] ?? '').toString().isNotEmpty &&
            (data['aadharCardBack'] ?? '').toString().isNotEmpty;

        panUploaded =
            (data['PanCardFront'] ?? '').toString().isNotEmpty &&
            (data['PanCardBack'] ?? '').toString().isNotEmpty;

        DrUploaded =
            (data['DrinvingLicenceFront'] ?? '').toString().isNotEmpty &&
            (data['DrivingLicenceBack'] ?? '').toString().isNotEmpty;

        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void handleNext() {
    if (aadharUploaded && panUploaded && DrUploaded) {
      Get.to(() => const DocumentsStatusPage());
    } else {
      Get.snackbar(
        'Incomplete',
        'Please upload all documents before proceeding.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              fetchUploadStatus();
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal documents',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload focused photos of below documents\nfor faster verification',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// Aadhaar
                  GestureDetector(
                    onTap: () async {
                      await Get.to(() => const AadharCardUploadPage());
                      await Future.delayed(const Duration(milliseconds: 300));
                      fetchUploadStatus();
                    },
                    child: _buildDocumentTile('Aadhar Card', aadharUploaded),
                  ),
                  const SizedBox(height: 12),

                  /// PAN
                  GestureDetector(
                    onTap: () async {
                      await Get.to(() => const pancard());
                      await Future.delayed(const Duration(milliseconds: 300));
                      fetchUploadStatus();
                    },
                    child: _buildDocumentTile('PAN Card', panUploaded),
                  ),
                  const SizedBox(height: 12),

                  /// Driving License
                  GestureDetector(
                    onTap: () async {
                      await Get.to(() => const DrivingLicence());
                      await Future.delayed(const Duration(milliseconds: 300));
                      fetchUploadStatus();
                    },
                    child: _buildDocumentTile('Driving License', DrUploaded),
                  ),

                  const Spacer(),

                  /// Next Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Next',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildDocumentTile(String title, bool isUploaded) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: isUploaded ? Colors.green : Colors.black),
        borderRadius: BorderRadius.circular(8),
        color: isUploaded ? Colors.green.shade50 : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isUploaded ? Colors.green : Colors.black,
            ),
          ),
          Icon(
            isUploaded ? Icons.check_circle : Icons.arrow_forward_ios,
            size: 16,
            color: isUploaded ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }
}
