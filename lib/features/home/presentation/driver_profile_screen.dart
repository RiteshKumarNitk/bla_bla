import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/ride/data/ride_repository.dart';

class DriverProfileScreen extends ConsumerWidget {
  final String driverId;
  final String driverName;

  const DriverProfileScreen({super.key, required this.driverId, required this.driverName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(driverStatsProvider(driverId));
    final reviewsAsync = ref.watch(driverReviewsProvider(driverId));

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Profile
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    child: Text(driverName[0].toUpperCase(), style: const TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(height: 16),
                  Text(driverName, style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Card
            statsAsync.when(
              data: (stats) {
                final rating = (stats['average_rating'] as num?)?.toDouble() ?? 0.0;
                final total = (stats['total_reviews'] as int?) ?? 0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('Rating', '${rating.toStringAsFixed(1)} ★', Colors.amber),
                        _buildStatItem('Reviews', '$total', Colors.blue),
                        // Placeholder for Rides Offered if we had it easily available, or just keeping it simple
                      ],
                    ),
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Error: $e'),
            ),
            
            const SizedBox(height: 24),
            Align(
               alignment: Alignment.centerLeft,
               child: Text('Reviews', style: Theme.of(context).textTheme.titleLarge)
            ),
            const SizedBox(height: 12),

            // Reviews List
            reviewsAsync.when(
              data: (reviews) {
                if (reviews.isEmpty) return const Text('No reviews yet.');
                return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                        final review = reviews[index];
                        final reviewerName = review['profiles'] != null ? review['profiles']['full_name'] : 'User';
                        final rating = review['rating'] as int;
                        final comment = review['comment'] as String?;
                        
                        return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                                leading: CircleAvatar(child: Text(reviewerName[0])),
                                title: Text(reviewerName),
                                subtitle: comment != null && comment.isNotEmpty ? Text(comment) : null,
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (i) => Icon(
                                        i < rating ? Icons.star : Icons.star_border,
                                        size: 16,
                                        color: Colors.amber,
                                    )),
                                ),
                            ),
                        );
                    },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e,s) => Text('Error loading reviews: $e'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

final driverStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) {
    return ref.read(rideRepositoryProvider).getUserStats(id);
});

final driverReviewsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) {
    return ref.read(rideRepositoryProvider).getUserReviews(id);
});
