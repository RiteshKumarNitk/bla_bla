class Message {
  final String id;
  final String rideId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isMine; // Helper for UI

  Message({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isMine = false,
  });

  factory Message.fromJson(Map<String, dynamic> json, String currentUserId) {
    return Message(
      id: json['id'],
      rideId: json['ride_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      isMine: json['sender_id'] == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ride_id': rideId,
      'sender_id': senderId,
      'content': content,
      // created_at is handled by DB default
    };
  }
}
