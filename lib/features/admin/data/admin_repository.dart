import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(Supabase.instance.client);
});

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository(this._supabase);

  // Fetch all profiles with role 'driver'
  Future<List<Map<String, dynamic>>> getDrivers() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('role', 'driver')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Toggle verification status
  Future<void> verifyDriver(String driverId, bool isVerified) async {
    await _supabase
        .from('profiles')
        .update({'is_verified': isVerified})
        .eq('id', driverId);
  }

  // Update additional driver info (Fleet management)
  Future<void> updateDriverInfo(String driverId, String dl, String aadhar, Map<String, dynamic> vehicle) async {
    await _supabase
        .from('profiles')
        .update({
          'dl_number': dl,
          'aadhar_number': aadhar,
          'vehicle_details': vehicle,
        })
        .eq('id', driverId);
  }

  // Shift Management
  Future<void> checkIn(String driverId) async {
    await _supabase.from('shift_logs').insert({
      'driver_id': driverId,
      'check_in_time': DateTime.now().toIso8601String(),
    });
  }

  Future<void> checkOut(String driverId) async {
    // Find latest open shift
    final response = await _supabase
        .from('shift_logs')
        .select()
        .eq('driver_id', driverId)
        .filter('check_out_time', 'is', null)
        .order('check_in_time', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      await _supabase
          .from('shift_logs')
          .update({'check_out_time': DateTime.now().toIso8601String()})
          .eq('id', response['id']);
    }
  }

  Future<Map<String, dynamic>?> getCurrentShift(String driverId) async {
     final response = await _supabase
        .from('shift_logs')
        .select()
        .eq('driver_id', driverId)
        .filter('check_out_time', 'is', null)
        .order('check_in_time', ascending: false)
        .limit(1)
        .maybeSingle();
     return response;
  }

  // Fleet Stats
  Future<Map<String, dynamic>> getFleetStats() async {
    // This is expensive with RLS if lists are huge, better to use an RPC function in postgres
    // For now, we do simple counts.
    final drivers = await _supabase.from('profiles').count(CountOption.exact).eq('role', 'driver');
    final activeShifts = await _supabase.from('shift_logs').count(CountOption.exact).filter('check_out_time', 'is', null);
    
    // Stats for Rides Today
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    
    final ridesToday = await _supabase
        .from('rides')
        .select('available_seats, total_seats')
        .gte('departure_time', todayStart);
    
    int totalSeats = 0;
    int availableSeats = 0;
    for(var r in ridesToday) {
       totalSeats += (r['total_seats'] as int);
       availableSeats += (r['available_seats'] as int);
    }
    
    int bookedSeats = totalSeats - availableSeats;
    
    return {
      'total_drivers': drivers,
      'active_drivers': activeShifts,
      'rides_today': ridesToday.length,
      'total_seats': totalSeats,
      'booked_seats': bookedSeats,
      'occupancy_rate': totalSeats > 0 ? (bookedSeats / totalSeats * 100).toStringAsFixed(1) : '0.0',
    };
  }
}

final allDriversProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getDrivers();
});
