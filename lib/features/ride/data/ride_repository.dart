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
    // SPECIAL CASE: Browse Mode (See All)
    // If origin and destination are empty, we just show all upcoming rides
    if (origin.isEmpty && destination.isEmpty) {
        final response = await _supabase
            .from('rides')
            .select('*, profiles(*)')
            .gt('available_seats', 0)
            .gt('departure_time', DateTime.now().toIso8601String())
            .order('departure_time', ascending: true)
            .limit(50);
        return (response as List).map((e) => Ride.fromJson(e)).toList();
    }

    // Normal Search Implementation
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));
    
    // Check if we are searching for today/future
    final now = DateTime.now();
    final isToday = startDate.year == now.year && startDate.month == now.month && startDate.day == now.day;

    // Build query with filters FIRST
    var query = _supabase
        .from('rides')
        .select('*, profiles(*)')
        .gt('available_seats', 0); // This returns PostgrestFilterBuilder

    // Apply strict date window for specific searches
    query = query.lt('departure_time', endDate.toIso8601String());

    if (origin.isNotEmpty) {
      query = query.ilike('origin', '%$origin%');
    }
    if (destination.isNotEmpty) {
      query = query.ilike('destination', '%$destination%');
    }

    if (isToday) {
       // specific filter for today: must be in future relative to NOW
       query = query.gt('departure_time', now.toIso8601String());
    } else {
       // future dates: just start of day
       query = query.gte('departure_time', startDate.toIso8601String());
    }

    // THEN apply order
    final response = await query.order('departure_time', ascending: true);

    return (response as List).map((e) => Ride.fromJson(e)).toList();
  }

  Future<void> createBooking(String rideId, String passengerId, int seats) async {
    // 1. Check if already booked
    final existing = await _supabase.from('bookings').select().eq('ride_id', rideId).eq('passenger_id', passengerId).maybeSingle();
    if (existing != null) {
      throw Exception('You have already requested this ride');
    }

    // 2. Create booking request (PENDING)
    // We DO NOT decrement seats yet.
    await _supabase.from('bookings').insert({
      'ride_id': rideId,
      'passenger_id': passengerId,
      'seats_booked': seats,
      'status': 'pending',
    });
  }

  Future<Map<String, dynamic>?> getBooking(String rideId, String userId) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('ride_id', rideId)
        .eq('passenger_id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> approveBooking(String bookingId, String rideId, int seats) async {
      // 1. Check availability again
      final rideData = await _supabase.from('rides').select().eq('id', rideId).single();
      final currentSeats = rideData['available_seats'] as int;
      
      if (currentSeats < seats) throw Exception('Not enough seats to approve');

      // 2. Decrement seats
      await _supabase.from('rides').update({
        'available_seats': currentSeats - seats
      }).eq('id', rideId);

      // 3. Update status
      await _supabase.from('bookings').update({
        'status': 'confirmed'
      }).eq('id', bookingId);
  }

  Future<void> rejectBooking(String bookingId) async {
      await _supabase.from('bookings').update({
        'status': 'rejected'
      }).eq('id', bookingId);
  }
  Future<List<Ride>> fetchNearbyRides(double lat, double lng) async {
      // For MVP, we fetch all valid rides and filter by distance locally or just show all
      // We filter for rides departing in the future.
      final response = await _supabase
        .from('rides')
        .select('*, profiles(*)')
        .gt('available_seats', 0)
        .gt('departure_time', DateTime.now().toIso8601String())
        .order('created_at', ascending: false)
        .limit(20);
      
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
  Future<void> updateRideLocation(String rideId, double lat, double lng) async {
    await _supabase.rpc('update_ride_location', params: {
      'ride_id_input': rideId,
      'lat': lat,
      'lng': lng,
    });
  }
  
  Stream<Ride> getRideStream(String rideId) {
    return _supabase.from('rides').stream(primaryKey: ['id']).eq('id', rideId).map((event) => Ride.fromJson(event.first));
  }

  Future<List<Map<String, dynamic>>> getRidePassengers(String rideId) async {
    final response = await _supabase
        .from('bookings')
        .select('*, profiles:passenger_id(*)')
        .eq('ride_id', rideId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateBookingPaymentStatus(String bookingId, String status) async {
    await _supabase
        .from('bookings')
        .update({'payment_status': status})
        .eq('id', bookingId);
  }
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final response = await _supabase.rpc('get_user_ratings_stats', params: {'user_id_input': userId});
    return response as Map<String, dynamic>;
  }
}

final offeredRidesProvider = FutureProvider.family<List<Ride>, String>((ref, userId) async {
  return ref.read(rideRepositoryProvider).getOfferedRides(userId);
});

final nearbyRidesProvider = FutureProvider<List<Ride>>((ref) async {
  return ref.read(rideRepositoryProvider).fetchNearbyRides(0, 0);
});
