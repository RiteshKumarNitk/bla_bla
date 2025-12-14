import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/auth/data/auth_repository_impl.dart';
import 'package:bla_bla/features/ride/data/ride_repository.dart';
import 'package:go_router/go_router.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
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
                                trailing: IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    onPressed: () {
                                        if (ride == null) return;
                                        context.push('/chat', extra: {
                                            'rideId': ride['id'],
                                            'title': "Ride to ${ride['destination']}",
                                        });
                                    },
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
                                trailing: IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    onPressed: () {
                                        context.push('/chat', extra: {
                                            'rideId': ride.id,
                                            'title': "Ride to ${ride.destination}",
                                        });
                                    },
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

