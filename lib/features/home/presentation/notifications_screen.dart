import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/admin/data/admin_repository.dart';
import 'package:bla_bla/features/auth/data/auth_repository_impl.dart';

final myNotificationsProvider = FutureProvider.autoDispose((ref) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) return <Map<String, dynamic>>[];
  
  // Directly fetching from repository (hack: using admin repository for now as it holds the generic fetch logic or we should move it)
  // Ideally: NotificationRepository. For speed: accessing supabase directly via AdminRepo helper or just adding a method here.
  // Let's assume we add getNotifications(userId) to AdminRepo or just do it inline here for MVP.
  // I'll update AdminRepository to include this.
  return ref.read(adminRepositoryProvider).getUserNotifications(user.id);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(myNotificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications & Offers")),
      body: notifsAsync.when(
        data: (notifs) => notifs.isEmpty 
            ? const Center(child: Text("No notifications yet"))
            : ListView.builder(
                itemCount: notifs.length,
                itemBuilder: (context, index) {
                  final n = notifs[index];
                  final isRead = n['is_read'] ?? false;
                  return Card(
                    color: isRead ? Colors.white : Colors.blue[50],
                    child: ListTile(
                      leading: Icon(Icons.local_offer, color: isRead ? Colors.grey : Colors.blue),
                      title: Text(n['title'] ?? 'Alert', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Text(n['message'] ?? ''),
                      trailing: Text(
                          (n['created_at'] as String).substring(0, 10), 
                          style: const TextStyle(color: Colors.grey, fontSize: 12)
                      ),
                    ),
                  );
                },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
