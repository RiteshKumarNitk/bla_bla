import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/auth/data/auth_repository_impl.dart';
import 'package:bla_bla/features/ride/data/ride_repository.dart';
import 'package:bla_bla/features/payment/data/wallet_repository.dart';
import 'package:go_router/go_router.dart';

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
        title: const Text("EMERGENCY SOS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("This will share your live location with emergency contacts and call police (112)."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calling Emergency Services...")));
              },
              icon: const Icon(Icons.call),
              label: const Text("CALL 112")
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
                  title: const Text("Rate Driver"),
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
                              decoration: const InputDecoration(labelText: "Comment (Optional)"),
                          )
                      ],
                  ),
                  actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
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
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review Submitted!")));
                          },
                          child: const Text("Submit"),
                      )
                  ],
              ),
          ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return const Center(child: Text("Please login"));

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
                    ? const Center(child: Text("No bookings yet")) 
                    : ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (ctx, i) {
                            final booking = bookings[i];
                            final ride = booking['rides']; // Joined data
                            return ListTile(
                                leading: const Icon(Icons.confirmation_number),
                                title: Text("Ride to ${ride?['destination'] ?? 'Unknown'}"),
                                subtitle: Text("Status: ${booking['status']}\nPrice: ₹${ride?['price'] ?? 0}"),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        // Chat
                                        IconButton(
                                            icon: const Icon(Icons.chat_bubble_outline),
                                            onPressed: () {
                                                if (ride == null) return;
                                                context.push('/chat', extra: {
                                                    'rideId': ride['id'],
                                                    'title': "Ride to ${ride['destination']}",
                                                });
                                            },
                                        ),
                                        // Rate (Simulated for any ride)
                                        IconButton(
                                            icon: const Icon(Icons.star_outline, color: Colors.amber),
                                            onPressed: () => _showRatingDialog(context, ref, ride!['id'], ride['driver_id']),
                                        ),
                                        // SOS (Simulated for active ride)
                                        IconButton(
                                            icon: const Icon(Icons.sos, color: Colors.red),
                                            onPressed: () => _showSOSDialog(context),
                                        ),
                                    ],
                                ),
                            );
                        }
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
            ),

            // OFFERED
            offeredAsync.when(
                data: (rides) => rides.isEmpty
                    ? const Center(child: Text("No rides offered yet"))
                    : ListView.builder(
                        itemCount: rides.length,
                        itemBuilder: (ctx, i) {
                            final ride = rides[i];
                            return ListTile(
                                leading: const Icon(Icons.local_taxi),
                                title: Text("To ${ride.destination}"),
                                subtitle: Text("${ride.availableSeats} seats left • ₹${ride.price.toInt()}"),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        // Chat
                                        IconButton(
                                            icon: const Icon(Icons.chat_bubble_outline),
                                            onPressed: () {
                                                context.push('/chat', extra: {
                                                    'rideId': ride.id,
                                                    'title': "Ride to ${ride.destination}",
                                                });
                                            },
                                        ),
                                        // Finish (Payment Simulation)
                                        IconButton(
                                            icon: const Icon(Icons.check_circle, color: Colors.green),
                                            tooltip: "Finish Ride & Collect Earnings",
                                            onPressed: () async {
                                                 final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                        title: const Text("Finish Ride?"),
                                                        content: Text("This will collect payment for all seats.\nEstimated Earnings: ₹${(ride.price * (ride.totalSeats - ride.availableSeats) * 0.9).toStringAsFixed(0)}"),
                                                        actions: [
                                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                                            ElevatedButton(
                                                                onPressed: () => Navigator.pop(ctx, true),
                                                                child: const Text("Finish")
                                                            )
                                                        ],
                                                    )
                                                 );
                                                 
                                                 if (confirm == true) {
                                                     // Calculate booked seats
                                                     final booked = ride.totalSeats - ride.availableSeats;
                                                     if (booked <= 0) {
                                                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No passengers to charge!")));
                                                         return;
                                                     }
                                                     
                                                     final total = ride.price * booked;
                                                     await ref.read(walletRepositoryProvider).processEarnings(
                                                         driverId: ride.driverId, 
                                                         amount: total, 
                                                         rideId: ride.id
                                                     );
                                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ride Completed! Wallet updated.")));
                                                 }
                                            },
                                        ),
                                    ],
                                ),
                            );
                        }
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
final bookingsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  return ref.read(rideRepositoryProvider).getBookings(userId);
});

final offeredRidesProvider = FutureProvider.family<List<dynamic>, String>((ref, userId) async {
  return ref.read(rideRepositoryProvider).getOfferedRides(userId);
});

