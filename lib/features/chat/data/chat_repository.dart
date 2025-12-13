import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/chat/domain/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  // Stream of messages for a specific ride
  Stream<List<Message>> getMessagesStream(String rideId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('ride_id', rideId)
        .order('created_at')
        .map((data) {
          final currentUserId = _supabase.auth.currentUser?.id ?? '';
          return data.map((e) => Message.fromJson(e, currentUserId)).toList();
        });
  }

  Future<void> sendMessage(String rideId, String content) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('messages').insert({
      'ride_id': rideId,
      'sender_id': user.id,
      'content': content,
    });
  }
}
