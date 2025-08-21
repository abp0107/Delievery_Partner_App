import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delievery_partner_app/Home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentsStatusPage extends StatelessWidget {
  const DocumentsStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('delivery_boys')
          .doc(userId)
          .collection('documents')
          .doc('status')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) {
          return const Scaffold(
            body: Center(child: Text("No document status found.")),
          );
        }

        final isAadharAccepted = data['aadhar'] == 'Accepted';
        final isPanAccepted = data['pan'] == 'Accepted';
        final isLicenseAccepted = data['license'] == 'Accepted';

        final allAccepted =
            isAadharAccepted && isPanAccepted && isLicenseAccepted;

        // ✅ Navigate if all are accepted
        if (allAccepted) {
          Future.microtask(() {
            Get.offAll(() => const OrdersPage());
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(''),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allAccepted ? 'Verified' : 'Waiting for Approval',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  allAccepted
                      ? 'Your documents have been approved.'
                      : 'Your documents are under review.\nYou will be notified once verified.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Status tiles
                _buildStatusTile("Aadhar Card", isAadharAccepted),
                _buildStatusTile("PAN Card", isPanAccepted),
                _buildStatusTile("Driving License", isLicenseAccepted),

                const Spacer(),
                if (!allAccepted)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Text(
                      '* You can continue once all documents are approved',
                      style: TextStyle(fontSize: 15, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTile(String title, bool isAccepted) {
    final color = isAccepted ? Colors.green : Colors.orange;
    final status = isAccepted ? "Accepted" : "Pending";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
