import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bla_bla/features/ride/domain/ride_model.dart';
import 'package:bla_bla/features/ride/data/ride_repository.dart';
import 'package:bla_bla/features/auth/data/auth_repository_impl.dart';

class RideDetailScreen extends ConsumerStatefulWidget {
  final Ride ride;

  const RideDetailScreen({super.key, required this.ride});

  @override
  ConsumerState<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends ConsumerState<RideDetailScreen> {
  // Placeholder for map controller
  late GoogleMapController _mapController;
  bool _isBooking = false;

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Future<void> _handleBooking() async {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to book")));
          return;
      }

      setState(() => _isBooking = true);

      try {
          await ref.read(rideRepositoryProvider).createBooking(widget.ride.id, user.id, 1);
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Confirmed!")));
              Navigator.of(context).pop();
          }
      } catch (e) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Booking Failed: $e")));
          }
      } finally {
          if (mounted) setState(() => _isBooking = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. Full Screen Map
          GoogleMap(
            initialCameraPosition: _kInitialPosition,
            myLocationEnabled: false, 
            zoomControlsEnabled: false,
            markers: {
                if (widget.ride.originLat != null && widget.ride.originLng != null)
                    Marker(
                        markerId: const MarkerId('origin'),
                        position: LatLng(widget.ride.originLat!, widget.ride.originLng!),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        infoWindow: InfoWindow(title: widget.ride.origin),
                    ),
                if (widget.ride.destLat != null && widget.ride.destLng != null)
                   Marker(
                        markerId: const MarkerId('dest'),
                        position: LatLng(widget.ride.destLat!, widget.ride.destLng!),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        infoWindow: InfoWindow(title: widget.ride.destination),
                   ),
            },
            polylines: {
                if (widget.ride.originLat != null && widget.ride.originLng != null && widget.ride.destLat != null && widget.ride.destLng != null)
                    Polyline(
                        polylineId: const PolylineId('route'),
                        points: [
                            LatLng(widget.ride.originLat!, widget.ride.originLng!),
                            LatLng(widget.ride.destLat!, widget.ride.destLng!),
                        ],
                        color: Colors.blue,
                        width: 5,
                    )
            },
            onMapCreated: (controller) {
                _mapController = controller;
                // Fit bounds
                if (widget.ride.originLat != null && widget.ride.originLng != null && widget.ride.destLat != null && widget.ride.destLng != null) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                        controller.animateCamera(CameraUpdate.newLatLngBounds(
                            LatLngBounds(
                                southwest: LatLng(
                                    widget.ride.originLat! < widget.ride.destLat! ? widget.ride.originLat! : widget.ride.destLat!,
                                    widget.ride.originLng! < widget.ride.destLng! ? widget.ride.originLng! : widget.ride.destLng!,
                                ),
                                northeast: LatLng(
                                    widget.ride.originLat! > widget.ride.destLat! ? widget.ride.originLat! : widget.ride.destLat!,
                                    widget.ride.originLng! > widget.ride.destLng! ? widget.ride.originLng! : widget.ride.destLng!,
                                ),
                            ),
                            50 // padding
                        ));
                    });
                }
            },
          ),

          // 2. Bottom Card
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: _buildDetailCard(context),
          ),
          
          // 3. Top Floating Info (Distance/Time)
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text("0 mile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Distance", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Icon(Icons.arrow_forward, color: Colors.redAccent),
                  Column(
                    children: [
                      Text("1 min", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Duration", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text("10:05 PM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Arrival", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Gradient Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4FC79), Color(0xFF96E6A1)], // Light Green gradient
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "#RIDE-₹${widget.ride.price.toInt()}", 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Status\n${widget.ride.availableSeats} seats available", 
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.local_taxi, size: 48, color: Colors.black26),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Details List
          _buildInfoRow("Driver", "John Doe"), // Placeholder
          _buildInfoRow("Car", widget.ride.carModel ?? "Toyota Prius"),
          _buildInfoRow("Origin", widget.ride.origin),
          _buildInfoRow("Destination", widget.ride.destination),
          _buildInfoRow("Payment", "Cash"),

          const SizedBox(height: 20),
          
          // CAUTION / Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Please ensure you arrive 5 minutes before departure.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),

          const SizedBox(height: 20),

          // Slide to Book Button
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(30),
            ),
            child: InkWell(
              onTap: _isBooking ? null : _handleBooking,
              borderRadius: BorderRadius.circular(30),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: _isBooking 
                        ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Icon(Icons.keyboard_double_arrow_right, color: Colors.white),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _isBooking ? "Booking..." : "Slide to book ride",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
