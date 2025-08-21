import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class DrivingLicence extends StatefulWidget {
  const DrivingLicence({super.key});

  @override
  State<DrivingLicence> createState() => _DrivingLicenceState();
}

class _DrivingLicenceState extends State<DrivingLicence> {
  File? _frontImage;
  File? _backImage;
  Uint8List? _frontFromDB;
  Uint8List? _backFromDB;

  @override
  void initState() {
    super.initState();
    _loadAadharImages();
  }

  Future<void> _loadAadharImages() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('delivery_boys')
        .doc(uid)
        .get();
    if (doc.exists) {
      final frontBase64 = doc['DrivingLicenceFront'] ?? '';
      final backBase64 = doc['DrinvingLicenceback'] ?? '';
      setState(() {
        _frontFromDB = frontBase64.isNotEmpty
            ? base64Decode(frontBase64)
            : null;
        _backFromDB = backBase64.isNotEmpty ? base64Decode(backBase64) : null;
      });
    }
  }

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(pickedFile.path);
        } else {
          _backImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<List<int>> _compressImage(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 600,
      minHeight: 600,
      quality: 60,
    );
    return result ?? await file.readAsBytes();
  }

  Widget _uploadBox({
    required String label,
    required VoidCallback onPressed,
    File? imageFile,
    Uint8List? imageBytes,
  }) {
    return Container(
      height: 250,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (imageFile != null)
              Positioned.fill(child: Image.file(imageFile, fit: BoxFit.cover))
            else if (imageBytes != null)
              Positioned.fill(
                child: Image.memory(imageBytes, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: (imageFile != null || imageBytes != null)
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.redAccent,
                    ),
                    label: Text(
                      "Upload Photo",
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitImages() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final data = <String, String>{};

      if (_frontImage != null) {
        final compressedFront = await _compressImage(_frontImage!);
        data['DrinvingLicenceFront'] = base64Encode(compressedFront);
      }

      if (_backImage != null) {
        final compressedBack = await _compressImage(_backImage!);
        data['DrivingLicenceBack'] = base64Encode(compressedBack);
      }

      if (data.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('delivery_boys')
            .doc(uid)
            .update(data);

        // Set document status to pending
        await FirebaseFirestore.instance
            .collection('delivery_boys')
            .doc(uid)
            .collection('documents')
            .doc('status')
            .set({'license': 'pending'}, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Licence images uploaded successfully!",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Licence card details",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            Text(
              "Upload focused photo of your Licence Card for faster verification",
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _uploadBox(
              label:
                  "Front side photo of your Licence  with your clear name and photo",
              onPressed: () => _pickImage(true),
              imageFile: _frontImage,
              imageBytes: _frontFromDB,
            ),
            _uploadBox(
              label:
                  "Back side photo of your Licence  with your clear name and photo",
              onPressed: () => _pickImage(false),
              imageFile: _backImage,
              imageBytes: _backFromDB,
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_frontImage != null || _backImage != null)
                    ? _submitImages
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  disabledBackgroundColor: Colors.redAccent.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Submit",
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
