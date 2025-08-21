import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delievery_partner_app/user_details.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'order_Details.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  int _selectedIndex = 0;
  bool isMealSelected = true;
  DateTime selectedDate = DateTime.now();

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xfff7f8fc),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOrdersView(formattedDate),
          _buildHistoryView(), // ✅ new tab for delivered orders
          const UserDetailsPage(),
        ],
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 15, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersView(String formattedDate) {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final ordersStream = FirebaseFirestore.instance
        .collection('orderRequests')
        .where('status', isEqualTo: isMealSelected ? 'accepted' : 'picked')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Column(
      children: [
        const SizedBox(height: 50),
        Text(
          "Orders",
          style: GoogleFonts.poppins(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color(0xffe0f2f1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      _buildToggleButton("NEW", isMealSelected, () {
                        setState(() => isMealSelected = true);
                      }),
                      _buildToggleButton("DELIVERED", !isMealSelected, () {
                        setState(() => isMealSelected = false);
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ordersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Column(
                  children: [
                    const SizedBox(height: 100),
                    Image.asset(
                      'assets/images/upscaled_no_orders_hd__1_-removebg-preview.png',
                      height: 300,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "No ${isMealSelected ? 'New' : 'Delivered'} Orders",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              }

              final orders = snapshot.data!.docs;

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final data = order.data() as Map<String, dynamic>;
                  final List<dynamic> items = data['items'] ?? [];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (items.isNotEmpty &&
                              items[0]['image'] != null &&
                              items[0]['image'].toString().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildBase64Image(items[0]['image']),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            data['name'] ?? 'No Name',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const Divider(
                            color: Colors.grey,
                            thickness: 1,
                            height: 20,
                          ),
                          Text(
                            "Phone: ${data['phone'] ?? ''}",
                            style: GoogleFonts.poppins(),
                          ),
                          Text(
                            "Address: ${data['address'] ?? ''}",
                            style: GoogleFonts.poppins(),
                          ),
                          Text(
                            "Payment: ${data['paymentMethod'] ?? ''}",
                            style: GoogleFonts.poppins(),
                          ),
                          const Divider(
                            color: Colors.grey,
                            thickness: 1,
                            height: 20,
                          ),
                          Text(
                            "Items:",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          ...items.map((item) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "- ${item['title']} x${item['title']}",
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                                Text(
                                  "  • Category: ${item['category'] ?? ''}",
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                                Text(
                                  "  • Price: ₹${item['price'] ?? ''}",
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                                Text(
                                  "  • Stock: ${item['stock'] ?? ''}",
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                              ],
                            );
                          }).toList(),
                          const Divider(
                            color: Colors.grey,
                            thickness: 1,
                            height: 20,
                          ),
                          Text(
                            "Total: ₹${data['totalAmount'] ?? ''}",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('orderRequests')
                                    .doc(order.id)
                                    .update({'status': 'picked'});

                                // FETCH SELLER ADDRESS
                                final sellerDoc = await FirebaseFirestore
                                    .instance
                                    .collection('seller_accounts')
                                    .doc('cN6oqc1jUKho4LWxjrflw6IFJhj2')
                                    .get();
                                final sellerAddress =
                                    sellerDoc.data()?['Address'] ?? 'Unknown';

                                final updatedData = {
                                  ...data,
                                  'sellerAddress': sellerAddress,
                                };
                                Get.to(OrderDetailsPage(order: updatedData));
                              },
                              child: Text(
                                isMealSelected ? "Pick Up" : "Track",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.green,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildBase64Image(String base64Image) {
  try {
    Uint8List bytes;
    if (base64Image.startsWith("data:image")) {
      final uriData = Uri.parse(base64Image).data;
      if (uriData != null) {
        bytes = uriData.contentAsBytes();
      } else {
        throw Exception("Invalid base64 URI");
      }
    } else {
      bytes = base64Decode(base64Image);
    }

    return Image.memory(
      bytes,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  } catch (_) {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
    );
  }
}

Widget _buildHistoryView() {
  final ordersStream = FirebaseFirestore.instance
      .collection('orderRequests')
      .where('status', isEqualTo: 'Delivered')
      .orderBy('timestamp', descending: true)
      .snapshots();

  return Column(
    children: [
      const SizedBox(height: 50),
      Text(
        "Delivered Orders",
        style: GoogleFonts.poppins(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 25),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: ordersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Column(
                children: [
                  const SizedBox(height: 100),
                  Image.asset(
                    'assets/images/upscaled_no_orders_hd__1_-removebg-preview.png',
                    height: 300,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "No Delivered Orders",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              );
            }

            final orders = snapshot.data!.docs;

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final data = order.data() as Map<String, dynamic>;
                final List<dynamic> items = data['items'] ?? [];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (items.isNotEmpty &&
                            items[0]['image'] != null &&
                            items[0]['image'].toString().isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildBase64Image(items[0]['image']),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          data['name'] ?? 'No Name',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const Divider(),
                        Text(
                          "Phone: ${data['phone'] ?? ''}",
                          style: GoogleFonts.poppins(),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Address: ${data['address']?['addressLine'] ?? 'No Address'}",
                          style: GoogleFonts.poppins(),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Payment: ${data['paymentMethod'] ?? ''}",
                          style: GoogleFonts.poppins(),
                        ),
                        const Divider(),
                        Text(
                          "Items:",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ...items.map((item) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "- ${item['title']} x${item['title']}",
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                              Text(
                                "  • Category: ${item['category'] ?? ''}",
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                              Text(
                                "  • Price: ₹${item['price'] ?? ''}",
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                              Text(
                                "  • Stock: ${item['stock'] ?? ''}",
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                            ],
                          );
                        }).toList(),
                        const Divider(),
                        Text(
                          "Total: ₹${data['totalAmount'] ?? ''}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}
