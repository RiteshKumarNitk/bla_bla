import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  // late GoogleMapController _mapController;
  bool _isBooking = false;
  
  bool get _isExpired {
    return widget.ride.departureTime.isBefore(DateTime.now());
  }

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Future<void> _handleBooking() async {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to book')));
          return;
      }

      setState(() => _isBooking = true);

      try {
          await ref.read(rideRepositoryProvider).createBooking(widget.ride.id, user.id, 1);
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Request Sent! Waiting for Driver Approval.'),
                  action: SnackBarAction(
                    label: 'CHAT',
                    onPressed: () {
                       context.push('/chat', extra: {
                          'rideId': widget.ride.id,
                          'title': "Ride to ${widget.ride.destination}",
                       });
                    },
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
              Navigator.of(context).pop();
          }
      } catch (e) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking Failed: $e')));
          }
      } finally {
          if (mounted) setState(() => _isBooking = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    final rideStream = ref.watch(rideStreamProvider(widget.ride.id));
    // Stream does not support joins, so we preserve driver info from the initial widget.ride
    final streamValue = rideStream.asData?.value;
    final liveRide = streamValue != null 
        ? streamValue.copyWith(
            driverName: widget.ride.driverName,
            // driverImage: widget.ride.driverImage, // Property does not exist
            // Keep other joined fields if necessary
          )
        : widget.ride;

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
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                onPressed: () {
                   context.push('/chat', extra: {
                      'rideId': widget.ride.id,
                      'title': "Ride to ${widget.ride.destination}",
                   });
                },
              ),
            ),
          ),
        ],
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
                if (liveRide.currentLat != null && liveRide.currentLng != null)
                   Marker(
                        markerId: const MarkerId('driver'),
                        position: LatLng(liveRide.currentLat!, liveRide.currentLng!),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                        infoWindow: const InfoWindow(title: 'Driver Location'),
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
            child: _buildDetailCard(context, liveRide),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text('--', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Distance', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.green),
                  Column(
                    children: [
                       Text(liveRide.departureTime.difference(DateTime.now()).isNegative 
                         ? 'Departed' 
                         : '${liveRide.departureTime.difference(DateTime.now()).inHours}h ${liveRide.departureTime.difference(DateTime.now()).inMinutes % 60}m', 
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       const Text('Until Leave', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('${liveRide.departureTime.hour.toString().padLeft(2, '0')}:${liveRide.departureTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Departure', style: TextStyle(color: Colors.grey, fontSize: 12)),
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

  Widget _buildDetailCard(BuildContext context, Ride ride) {
    final myBookingAsync = ref.watch(myBookingStreamProvider(widget.ride.id));
    final myBooking = myBookingAsync.asData?.value;
    
    String buttonText = _isExpired ? 'Ride Departed' : (_isBooking ? 'Requesting...' : 'Slide to Request Ride');
    Color buttonColor = _isExpired ? Colors.grey : Colors.redAccent;
    bool isDisabled = _isExpired || _isBooking;
    
    if (myBooking != null) {
        final status = myBooking['status'];
        if (status == 'pending') {
             buttonText = 'Request Pending';
             buttonColor = Colors.orange;
             isDisabled = true;
        } else if (status == 'confirmed') {
             buttonText = 'Ride Confirmed!';
             buttonColor = Colors.green;
             isDisabled = true; // Use this to maybe show ticket?
        } else if (status == 'rejected') {
             buttonText = 'Request Rejected';
             buttonColor = Colors.red;
             isDisabled = true; // Maybe allow retry?
        }
    }

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
              gradient: LinearGradient(
                colors: _isExpired 
                    ? [Colors.grey[300]!, Colors.grey[400]!]
                    : [const Color(0xFFD4FC79), const Color(0xFF96E6A1)], // Light Green gradient
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
                        '#RIDE-₹${ride.price.toInt()}', 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isExpired 
                            ? 'Ride has departed' 
                            : 'Status\n${ride.availableSeats} seats available',
                        style: TextStyle(
                            fontSize: 12, 
                            color: _isExpired ? Colors.red : Colors.black54
                        ),
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
          InkWell(
            onTap: () {
                context.push('/driver_profile', extra: {'id': widget.ride.driverId, 'name': ride.driverName ?? 'Driver'});
            },
            child: _buildInfoRow('Driver', ride.driverName ?? 'Unknown Driver', 
                textColor: Colors.blue, 
                trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.blue)
            ),
          ),
          _buildInfoRow('Car', ride.carModel ?? 'Toyota Prius'),
          _buildInfoRow('Origin', ride.origin),
          _buildInfoRow('Destination', ride.destination),
          _buildInfoRow('Payment', 'Cash'),

          const SizedBox(height: 20),
          
          // CAUTION / Note
          if (myBooking != null && myBooking['status'] == 'confirmed')
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                    children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(child: Text('Your ride is confirmed! Please be at the pickup point on time.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    ],
                ),
              )
          else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Please ensure you arrive 5 minutes before departure.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

          if (myBooking == null || myBooking['status'] != 'confirmed')
             const SizedBox(height: 20),

          // Slide to Book Button
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: buttonColor.withOpacity(0.1), // Light background
              borderRadius: BorderRadius.circular(30),
            ),
            child: InkWell(
              onTap: isDisabled ? null : _handleBooking,
              borderRadius: BorderRadius.circular(30),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      shape: BoxShape.circle,
                    ),
                    child: _isBooking 
                        ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : Icon(isDisabled ? Icons.lock : Icons.keyboard_double_arrow_right, color: Colors.white),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        buttonText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: buttonColor
                        ),
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

  Widget _buildInfoRow(String label, String value, {Color? textColor, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Row(
            children: [
               Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
               if (trailing != null) ...[
                 const SizedBox(width: 4),
                 trailing,
               ]
            ],
          ),
        ],
      ),
    );
  }
}

final rideStreamProvider = StreamProvider.family<Ride, String>((ref, rideId) {
  return ref.watch(rideRepositoryProvider).getRideStream(rideId);
});

final myBookingStreamProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, rideId) {
    // Watch auth changes to ensure we have user
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return Stream.value(null);
    
    // We access Supabase directly for stream or via repository if we added a stream method
    // For now direct access is easiest given constraints, but typically via repo.
    // Let's assume we can access instance.
    return Supabase.instance.client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('ride_id', rideId)
        .map((events) {
            final myBooking = events.firstWhere(
              (element) => element['passenger_id'] == user.id, 
              orElse: () => {},
            );
            return myBooking.isNotEmpty ? myBooking : null;
        });
});
