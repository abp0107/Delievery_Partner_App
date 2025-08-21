import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delievery_partner_app/Log_In_PAges/Phone_Auth.dart';
import 'package:delievery_partner_app/personal_information_pages/opload_documents.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class UserDetailsPage extends StatelessWidget {
  const UserDetailsPage({super.key});

  Future<Map<String, dynamic>?> getUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('delivery_boys')
        .doc(userId)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!;
        return Scaffold(
          backgroundColor: const Color(0xfff7f8fc),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: Text(
                      "Account",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundImage: AssetImage(
                          'assets/images/delivery_boy.png',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['FullName'] ?? 'Name',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            data['MobileNumber'] ?? '',
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                          Text(
                            data['Address'] ?? '',
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildListTile(Icons.edit, "Add Documents"),
              _buildListTile(Icons.map, "Allotted Area"),
              _buildListTile(Icons.card_giftcard, "Refer and Earn"),
              _buildListTile(Icons.support_agent, "Support"),
              _buildListTile(Icons.help_outline, "FAQ"),
              _buildListTile(Icons.article, "Terms and Conditions"),
              _buildListTile(Icons.privacy_tip, "Privacy Policy"),
              _buildListTile(Icons.leave_bags_at_home, "Ask for Leave"),
              _buildListTile(
                Icons.logout,
                "Log Out",
                isRed: true,
                context: context,
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "App Version 1.0.0 (30)",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title, {
    bool isRed = false,
    BuildContext? context,
  }) {
    return ListTile(
      leading: Icon(icon, color: isRed ? Colors.red : Colors.black),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isRed ? Colors.red : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        if (title == "Log Out" && context != null) {
          await FirebaseAuth.instance.signOut();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => PhoneInputPage()),
            (route) => false,
          );
        } else if (title == "Add Documents") {
          Get.to(PersonalDocumentsPage());
        } else {
          print('$title tapped');
        }
      },
    );
  }
}
