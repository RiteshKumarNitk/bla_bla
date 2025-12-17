class Ride {
  final String id;
  final String driverId;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final double price;
  final int totalSeats;
  final int availableSeats;
  final String? carModel;
  final double? originLat;
  final double? originLng;
  final double? destLat;
  final double? destLng;
  final double? currentLat;
  final double? currentLng;

  Ride({
    required this.id,
    required this.driverId,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.price,
    required this.totalSeats,
    required this.availableSeats,
    this.carModel,
    this.originLat,
    this.originLng,
    this.destLat,
    this.destLng,
    this.currentLat,
    this.currentLng,
    this.driverName,
    this.driverRating,
    this.driverTotalReviews,
  });

  final String? driverName;
  final double? driverRating;
  final int? driverTotalReviews;

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      driverId: json['driver_id'],
      origin: json['origin'],
      destination: json['destination'],
      departureTime: DateTime.parse(json['departure_time']),
      price: json['price'].toDouble(),
      totalSeats: json['total_seats'],
      availableSeats: json['available_seats'],
      carModel: json['car_model'],
      originLat: json['origin_lat'] != null ? (json['origin_lat'] as num).toDouble() : null,
      originLng: json['origin_lng'] != null ? (json['origin_lng'] as num).toDouble() : null,
      destLat: json['dest_lat'] != null ? (json['dest_lat'] as num).toDouble() : null,
      destLng: json['dest_lng'] != null ? (json['dest_lng'] as num).toDouble() : null,
      currentLat: json['current_lat'] != null ? (json['current_lat'] as num).toDouble() : null,
      currentLng: json['current_lng'] != null ? (json['current_lng'] as num).toDouble() : null,
      driverName: json['profiles'] != null ? json['profiles']['full_name'] : null,
      driverRating: 0.0, 
      driverTotalReviews: 0,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'driver_id': driverId,
      'origin': origin,
      'destination': destination,
      'departure_time': departureTime.toIso8601String(),
      'price': price,
      'total_seats': totalSeats,
      'available_seats': availableSeats,
      'car_model': carModel,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'current_lat': currentLat,
      'current_lng': currentLng,
    };
    // Include ID if it's not empty, otherwise let DB generate it
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
  Ride copyWith({
    String? id,
    String? driverId,
    String? origin,
    String? destination,
    DateTime? departureTime,
    double? price,
    int? totalSeats,
    int? availableSeats,
    String? carModel,
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
    double? currentLat,
    double? currentLng,
    String? driverName,
    double? driverRating,
    int? driverTotalReviews,
  }) {
    return Ride(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      price: price ?? this.price,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      carModel: carModel ?? this.carModel,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destLat: destLat ?? this.destLat,
      destLng: destLng ?? this.destLng,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      driverName: driverName ?? this.driverName,
      driverRating: driverRating ?? this.driverRating,
      driverTotalReviews: driverTotalReviews ?? this.driverTotalReviews,
    );
  }
}

