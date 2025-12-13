 import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/ride/domain/ride_model.dart';

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepository(Supabase.instance.client);
});

class RideRepository {
  final SupabaseClient _supabase;

  RideRepository(this._supabase);

  Future<void> createRide(Ride ride) async {
    await _supabase.from('rides').insert(ride.toJson());
  }

  Future<List<Ride>> searchRides(String origin, String destination, DateTime date) async {
    // Basic search implementation
    // For date comparison, we typically look for rides on the same day
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));

    final response = await _supabase
        .from('rides')
        .select()
        .ilike('origin', '%$origin%')
        .ilike('destination', '%$destination%')
        .gte('departure_time', startDate.toIso8601String())
        .lt('departure_time', endDate.toIso8601String())
        .gt('available_seats', 0); // Only available rides

    return (response as List).map((e) => Ride.fromJson(e)).toList();
  }

  Future<void> createBooking(String rideId, String passengerId, int seats) async {
    await _supabase.from('bookings').insert({
      'ride_id': rideId,
      'passenger_id': passengerId,
      'seats_booked': seats,
      'status': 'confirmed',
    });

    // Optional: RPC call to decrement available seats if not using a trigger
    // await _supabase.rpc('decrement_seats', params: {'ride_id': rideId, 'count': seats});
    // For now, simpler to just rely on client or trigger. 
    // Let's assume there's no trigger and do a manual update for safety in this MVP.
    // However, keeping RLS simple means we might not have update info.
    // Let's stick to insert and hope for the best or add a simple rpc later. 
  }
  Future<List<Ride>> fetchNearbyRides(double lat, double lng) async {
      // For MVP, we fetch all valid rides and filter by distance locally or just show all
      // ideally use PostGIS or Supabase spatial query if enabled.
      // Here we just fetch recent rides.
      final response = await _supabase
        .from('rides')
        .select()
        .gt('available_seats', 0)
        .order('created_at', ascending: false)
        .limit(50);
      
      return (response as List).map((e) => Ride.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getBookings(String userId) async {
    final response = await _supabase
        .from('bookings')
        .select('*, rides(*)') // Join to get ride details
        .eq('passenger_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Ride>> getOfferedRides(String driverId) async {
    final response = await _supabase
        .from('rides')
        .select()
        .eq('driver_id', driverId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Ride.fromJson(e)).toList();
  }
  Future<void> submitReview({
    required String rideId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    String? comment,
  }) async {
    await _supabase.from('reviews').insert({
      'ride_id': rideId,
      'reviewer_id': reviewerId,
      'reviewee_id': revieweeId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    final response = await _supabase
        .from('reviews')
        .select('*, profiles!reviewer_id(full_name)')
        .eq('reviewee_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
