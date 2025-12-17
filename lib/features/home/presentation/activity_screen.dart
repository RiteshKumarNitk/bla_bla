import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/auth/data/auth_repository_impl.dart';
import 'package:bla_bla/features/ride/data/ride_repository.dart';
import 'package:bla_bla/features/payment/data/wallet_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:bla_bla/features/ride/domain/ride_model.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('EMERGENCY SOS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('This will share your live location with emergency contacts and call police (112).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling Emergency Services...')));
              },
              icon: const Icon(Icons.call),
              label: const Text('CALL 112')
          )
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref, String rideId, String driverId) {
      int rating = 5;
      final commentController = TextEditingController();
      
      showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                  title: const Text('Rate Driver'),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) => IconButton(
                                  icon: Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                                  onPressed: () => setState(() => rating = index + 1),
                              )),
                          ),
                          TextField(
                              controller: commentController,
                              decoration: const InputDecoration(labelText: 'Comment (Optional)'),
                          )
                      ],
                  ),
                  actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      ElevatedButton(
                          onPressed: () async {
                              final user = ref.read(authRepositoryProvider).currentUser;
                              if (user == null) return;
                              
                              await ref.read(rideRepositoryProvider).submitReview(
                                  rideId: rideId, 
                                  reviewerId: user.id, 
                                  revieweeId: driverId, 
                                  rating: rating,
                                  comment: commentController.text
                              );
                              if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review Submitted!')));
                              }
                          },
                          child: const Text('Submit'),
                      )
                  ],
              ),
          ),
      );
  }

  void _showPaymentInfoDialog(BuildContext context, Map<String, dynamic> booking, Map<String, dynamic>? ride) {
      final price = ride?['price'] ?? 0;
      final seats = booking['seats_booked'] ?? 1;
      final total = price * seats;
      final driverName = "Driver"; // In a real app, join driver profile

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(children: [Icon(Icons.payments, color: Colors.green), SizedBox(width: 8), Text('Payment Details')]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please pay cash to the driver upon arrival.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              _buildDetailRow('Amount Due', '₹${total.toStringAsFixed(0)}'),
              _buildDetailRow('Status', (booking['payment_status'] == 'paid') ? 'PAID' : 'PENDING', 
                  color: (booking['payment_status'] == 'paid') ? Colors.green : Colors.orange),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }

  void _showPassengersDialog(BuildContext context, Ride ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Passengers & Payments', style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: ref.read(rideRepositoryProvider).getRidePassengers(ride.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final bookings = snapshot.data!;
                  
                  if (bookings.isEmpty) {
                    return const Center(child: Text('No passengers yet'));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: bookings.length,
                    itemBuilder: (ctx, i) {
                      final booking = bookings[i];
                      final profile = booking['profiles'] ?? {};
                      final name = profile['full_name'] ?? 'Passenger';
                      final seats = booking['seats_booked'] as int;
                      final total = ride.price * seats;
                      final status = booking['status'] ?? 'pending';
                      final paymentStatus = booking['payment_status'] ?? 'pending';
                      final isPaid = paymentStatus == 'paid';

                      return ListTile(
                        leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0] : 'P')),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text('$seats seats • Total: ₹${total.toStringAsFixed(0)}'),
                             if (status == 'pending')
                               const Text('Status: REQUESTED', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
                             else
                               Text('Status: ${status.toString().toUpperCase()}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: status == 'pending' 
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                               IconButton(
                                 icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                                 onPressed: () async {
                                    try {
                                        await ref.read(rideRepositoryProvider).approveBooking(booking['id'], ride.id, seats);
                                        if (context.mounted) {
                                            Navigator.pop(ctx);
                                            _showPassengersDialog(context, ride);
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Accepted!')));
                                        }
                                    } catch (e) {
                                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                 },
                               ),
                               IconButton(
                                 icon: const Icon(Icons.cancel, color: Colors.red, size: 32),
                                 onPressed: () async {
                                     await ref.read(rideRepositoryProvider).rejectBooking(booking['id']);
                                     if (context.mounted) {
                                         Navigator.pop(ctx);
                                         _showPassengersDialog(context, ride);
                                     }
                                 },
                               ),
                            ],
                          )
                        : isPaid 
                          ? const Chip(label: Text('PAID'), backgroundColor: Colors.greenAccent)
                          : ElevatedButton(
                                onPressed: () async {
                                  await ref.read(rideRepositoryProvider).updateBookingPaymentStatus(booking['id'], 'paid');
                                  if (context.mounted) {
                                     setState(() {}); 
                                     Navigator.pop(ctx);
                                     _showPassengersDialog(context, ride); 
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Mark Received'),
                            ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return const Center(child: Text('Please login'));

    final bookingsAsync = ref.watch(bookingsProvider(user.id));
    final offeredAsync = ref.watch(offeredRidesProvider(user.id));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Booked'),
              Tab(text: 'Offered'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // BOOKINGS
            bookingsAsync.when(
                data: (bookings) => bookings.isEmpty 
                    ? RefreshIndicator(
                        onRefresh: () => ref.refresh(bookingsProvider(user.id).future),
                        child: LayoutBuilder(
                           builder: (context, constraints) => SingleChildScrollView(
                             physics: const AlwaysScrollableScrollPhysics(),
                             child: ConstrainedBox(
                               constraints: BoxConstraints(minHeight: constraints.maxHeight),
                               child: const Center(child: Text('No bookings yet')),
                             ),
                           ),
                         ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(bookingsProvider(user.id).future),
                        child: ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (ctx, i) {
                            final booking = bookings[i];
                            final ride = booking['rides']; // Joined data
                            return ListTile(
                                leading: const Icon(Icons.confirmation_number),
                                title: Text("Ride to ${ride?['destination'] ?? 'Unknown'}"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Status: ${booking['status'].toString().toUpperCase()}"),
                                    Text(
                                      "Payment: ${booking['payment_status']?.toString().toUpperCase() ?? 'PENDING'} • ₹${ride?['price'] ?? 0}",
                                      style: TextStyle(
                                        color: (booking['payment_status'] == 'paid') ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        // Chat
                                        IconButton(
                                            icon: const Icon(Icons.chat_bubble_outline),
                                            tooltip: 'Chat with Driver',
                                            onPressed: () {
                                                if (ride == null) return;
                                                context.push('/chat', extra: {
                                                    'rideId': ride['id'],
                                                    'title': "Ride to ${ride['destination']}",
                                                });
                                            },
                                        ),
                                        // Pay / Info
                                        IconButton(
                                            icon: Icon(
                                              Icons.payments_outlined, 
                                              color: (booking['payment_status'] == 'paid') ? Colors.green : Colors.orange
                                            ),
                                            tooltip: 'Payment Info',
                                            onPressed: () => _showPaymentInfoDialog(context, booking, ride),
                                        ),
                                        // SOS (Simulated for active ride)
                                        IconButton(
                                            icon: const Icon(Icons.sos, color: Colors.red),
                                            onPressed: () => _showSOSDialog(context),
                                        ),
                                        // Rate (Simulated for any ride)
                                        IconButton(
                                            icon: const Icon(Icons.star_outline, color: Colors.amber),
                                            onPressed: () => _showRatingDialog(context, ref, ride!['id'], ride['driver_id']),
                                        ),
                                    ],
                                ),
                            );
                        }
                    ),
                  ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
            ),

            // OFFERED
            offeredAsync.when(
                data: (rides) => rides.isEmpty
                    ? RefreshIndicator(
                         onRefresh: () => ref.refresh(offeredRidesProvider(user.id).future),
                         child: LayoutBuilder(
                           builder: (context, constraints) => SingleChildScrollView(
                             physics: const AlwaysScrollableScrollPhysics(),
                             child: ConstrainedBox(
                               constraints: BoxConstraints(minHeight: constraints.maxHeight),
                               child: const Center(child: Text('No rides offered yet')),
                             ),
                           ),
                         ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(offeredRidesProvider(user.id).future),
                        child: ListView.builder(
                        itemCount: rides.length,
                        itemBuilder: (ctx, i) {
                            final ride = rides[i];
                            return ListTile(
                                leading: const Icon(Icons.local_taxi),
                                title: Text('${ride.origin} → ${ride.destination}'),
                                subtitle: Text('${ride.availableSeats} seats left • ₹${ride.price.toInt()}'),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        // Chat
                                        IconButton(
                                            icon: const Icon(Icons.chat_bubble_outline),
                                            onPressed: () {
                                                context.push('/chat', extra: {
                                                    'rideId': ride.id,
                                                    'title': 'Ride to ${ride.destination}',
                                                });
                                            },
                                        ),
                                        // Update Location
                                        IconButton(
                                            icon: const Icon(Icons.my_location, color: Colors.blue),
                                            tooltip: 'Update Live Location',
                                            onPressed: () async {
                                                LocationPermission permission = await Geolocator.checkPermission();
                                                if (permission == LocationPermission.denied) {
                                                    permission = await Geolocator.requestPermission();
                                                    if (permission == LocationPermission.denied) return;
                                                }
                                                
                                                final pos = await Geolocator.getCurrentPosition();
                                                await ref.read(rideRepositoryProvider).updateRideLocation(ride.id, pos.latitude, pos.longitude);
                                                
                                                if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location Updated: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}')));
                                                }
                                            },
                                        ),
                                        // Payment / Passengers
                                        IconButton(
                                            icon: const Icon(Icons.people_alt, color: Colors.green),
                                            tooltip: 'Manage Passengers & Payments',
                                            onPressed: () => _showPassengersDialog(context, ride),
                                        ),

                                    ],
                                ),
                            );
                        }
                    ),
                  ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }
}

// Providers
final bookingsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  return ref.read(rideRepositoryProvider).getBookings(userId);
});
