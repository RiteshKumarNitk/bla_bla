import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/ride/data/ride_repository.dart';
import 'package:bla_bla/features/ride/domain/ride_model.dart';
import 'package:go_router/go_router.dart';

// Provider for search parameters
final searchRidesProvider = FutureProvider.family<List<Ride>, Map<String, dynamic>>((ref, params) async {
  final repository = ref.watch(rideRepositoryProvider);
  return repository.searchRides(
    params['origin'],
    params['destination'],
    params['date'],
  );
});

class SearchResultsScreen extends ConsumerWidget {
  final String origin;
  final String destination;
  final DateTime date;

  const SearchResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsyncValue = ref.watch(searchRidesProvider({
      'origin': origin,
      'destination': destination,
      'date': date,
    }));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$origin → $destination', style: const TextStyle(fontSize: 16)),
            Text(
              "${date.toLocal()}".split(' ')[0], 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: ridesAsyncValue.when(
        data: (rides) {
          if (rides.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No rides found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: rides.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final ride = rides[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${ride.departureTime.hour}:${ride.departureTime.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                         "₹${ride.price.toStringAsFixed(0)}",
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.circle_outlined, size: 12),
                          const SizedBox(width: 8),
                          Text(ride.origin),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 5),
                        height: 12,
                        decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: Colors.grey, width: 1)),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12),
                          const SizedBox(width: 8),
                          Text(ride.destination),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.event_seat, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${ride.availableSeats} seats left'),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push('/ride_detail', extra: ride);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
