import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LiveTrackingMapScreen extends StatefulWidget {
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final String orderId;

  const LiveTrackingMapScreen({
    super.key,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.orderId,
  });

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Location _location = Location();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  LatLng? _currentLatLng;
  BitmapDescriptor? _bikeIcon;
  StreamSubscription<LocationData>? _locationSubscription;

  Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];

  bool _showRoute = false;
  bool _showDeliveredButton = false;

  @override
  void initState() {
    super.initState();
    _setCustomMarker();
    _initLocation();
  }

  Future<void> _setCustomMarker() async {
    _bikeIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      'assets/images/delivery.png',
    );
  }

  Future<void> _initLocation() async {
    final locData = await _location.getLocation();
    _currentLatLng = LatLng(locData.latitude!, locData.longitude!);
    if (mounted) {
      setState(() {});
    }

    _locationSubscription = _location.onLocationChanged.listen((newLoc) {
      if (!mounted) return;
      setState(() {
        _currentLatLng = LatLng(newLoc.latitude!, newLoc.longitude!);
        if (_showRoute) _getPolylinePoints();
      });
    });
  }

  Future<void> _getPolylinePoints() async {
    if (_currentLatLng == null) return;

    _polylineCoordinates.clear();
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: 'YOUR_API_KEY',
      request: PolylineRequest(
        origin: PointLatLng(
          _currentLatLng!.latitude,
          _currentLatLng!.longitude,
        ),
        destination: PointLatLng(widget.destinationLat, widget.destinationLng),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      if (mounted) {
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points: _polylineCoordinates,
            ),
          };
        });
      }
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentLatLng == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLatLng!,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('deliveryBoy'),
                      position: _currentLatLng!,
                      icon: _bikeIcon ?? BitmapDescriptor.defaultMarker,
                      infoWindow: const InfoWindow(title: "Delivery Boy"),
                    ),
                    Marker(
                      markerId: const MarkerId('customer'),
                      position: LatLng(
                        widget.destinationLat,
                        widget.destinationLng,
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                      infoWindow: const InfoWindow(title: "Customer Location"),
                    ),
                  },
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),

                // 🎉 Confetti blast
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    numberOfParticles: 30,
                    gravity: 0.2,
                    emissionFrequency: 0.05,
                  ),
                ),

                // 👉 Start Direction Button
                if (!_showRoute)
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('orderRequests')
                              .doc(widget.orderId)
                              .update({'status': "Out For Delivery"});

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Status updated to "Out For Delivery"',
                              ),
                            ),
                          );

                          setState(() {
                            _showRoute = true;
                            _showDeliveredButton = true;
                          });

                          //await _getPolylinePoints();
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Start Direction",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),

                // ✅ Item Delivered Button
                if (_showDeliveredButton)
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('orderRequests')
                              .doc(widget.orderId)
                              .update({'status': "Delivered"});

                          _confettiController.play(); // 🎉 Play confetti

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '🎉 Congratulations! Order Delivered 🎉',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: Colors.green.shade700,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              duration: const Duration(seconds: 2),
                              elevation: 10,
                            ),
                          );

                          Future.delayed(const Duration(seconds: 2), () {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Item Delivered",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
