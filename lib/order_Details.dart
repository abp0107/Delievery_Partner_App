import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Delievery_map_screen.dart'; // Your live map screen

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsPage({super.key, required this.order});

  void _openMap(String address) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = order['items'] ?? [];
    final sellerAddress = order['sellerAddress']?.toString() ?? 'Not Available';
    final customerAddress = order['address']?.toString() ?? 'Not Available';
    final customerAddressMap = order['address'] as Map<String, dynamic>?;
    final customerAddressLine =
        customerAddressMap?['addressLine'] ?? 'Not Available';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Order Info"),
              _infoRow("Name", order['name'] ?? ''),
              _infoRow("Phone", order['phone'] ?? ''),
              _infoRow("Payment Method", order['paymentMethod'] ?? ''),
              _infoRow("Total Amount", "₹${order['totalAmount'].toString()}"),

              const Divider(height: 30),

              _sectionTitle("Items"),
              ...items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(
                        "Title",
                        "${item['title'] ?? ''} x${item['qty'] ?? 1}",
                      ),
                      _smallInfo("Category", item['category'] ?? ''),
                      _smallInfo("Price", "₹${item['price'].toString()}"),
                      _smallInfo("Stock", item['stock'].toString()),
                    ],
                  ),
                );
              }),

              const Divider(height: 30),

              _sectionTitle("Addresses"),

              const SizedBox(height: 12),

              _addressBox(
                label: "Seller Address",
                address: sellerAddress,
                onTap: () => _openMap(sellerAddress),
              ),

              const SizedBox(height: 16),

              _addressBox(
                label: "Customer Address",
                address: customerAddressLine,
                onTap: () async {
                  try {
                    List<Location> locations = await locationFromAddress(
                      customerAddress,
                    );
                    if (locations.isNotEmpty) {
                      final lat = locations.first.latitude;
                      final lng = locations.first.longitude;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveTrackingMapScreen(
                            destinationAddress: customerAddress,
                            destinationLat: lat,
                            destinationLng: lng,
                            orderId: order['orderId'],
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Could not find location"),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          Flexible(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  Widget _smallInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Text("• ", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          Text(
            "$label: ",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          Flexible(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  Widget _addressBox({
    required String label,
    required String address,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              address,
              style: GoogleFonts.poppins(color: Colors.blue, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
