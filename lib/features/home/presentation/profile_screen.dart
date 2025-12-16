import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/auth/presentation/auth_controller.dart';
import 'package:bla_bla/features/auth/data/auth_repository_impl.dart';
import 'package:bla_bla/features/ride/data/ride_repository.dart';
import 'package:bla_bla/features/admin/data/admin_repository.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();

  void _showEditProfileDialog(String? currentName) {
    _nameController.text = currentName ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authRepositoryProvider).updateProfile(name: _nameController.text);
              if (mounted) {
                  setState(() {}); // Refresh UI
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDriverDetailsDialog(BuildContext context, WidgetRef ref, String userId, Map<String, dynamic>? meta) {
    final dlController = TextEditingController(text: meta?['dl_number']);
    final rcController = TextEditingController(text: meta?['vehicle_details']?['plate']);
    final modelController = TextEditingController(text: meta?['vehicle_details']?['model']);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Driver Details'),
        content: SingleChildScrollView(
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               TextField(controller: dlController, decoration: const InputDecoration(labelText: 'License Number (DL)')),
               const SizedBox(height: 10),
               TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Car Model (e.g. Swift)')),
               const SizedBox(height: 10),
               TextField(controller: rcController, decoration: const InputDecoration(labelText: 'Number Plate (RC)')),
             ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
                final vehicle = {'model': modelController.text, 'plate': rcController.text};
                // Note: Ideally we'd move updateDriverInfo to a generic repo accessible by user, 
                // but for now AdminRepo contains the logic and RLS might block it.
                // Wait, RLS for profiles usually allows 'update' for 'id = auth.uid()'.
                // So calling the supabase update directly here or via repo is fine.
                // We'll use the repo method but ensure it works for self.
                await ref.read(adminRepositoryProvider).updateDriverInfo(userId, dlController.text, '', vehicle);
                if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details Updated')));
                }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final fullName = user?.userMetadata?['full_name'] as String?;
    
    // Fetch rating stats (could be optimized)
    final reviewsAsync = user != null ? ref.watch(userReviewsProvider(user.id)) : const AsyncValue.loading();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 50,
            child: Text(
              fullName?.isNotEmpty == true ? fullName![0].toUpperCase() : (user?.email?.substring(0, 1).toUpperCase() ?? 'U'),
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  fullName ?? 'User',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? 'Guest',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                 reviewsAsync.when(
                  data: (reviews) {
                    if (reviews.isEmpty) return const Text('No ratings yet', style: TextStyle(color: Colors.orange));
                    
                    double total = 0;
                    for(var r in reviews) {
                      total += (r['rating'] as int);
                    }
                    final average = total / reviews.length;
                    
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         const Icon(Icons.star, color: Colors.amber, size: 20),
                         const SizedBox(width: 4),
                         Text(
                             '${average.toStringAsFixed(1)} (${reviews.length} reviews)',
                             style: const TextStyle(fontWeight: FontWeight.bold),
                         ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (err, stack) => Text('Error loading ratings', style: TextStyle(color: Colors.red[200], fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Driver Shift Control
          if (user?.userMetadata?['role'] == 'driver')
            Consumer(
              builder: (context, ref, _) {
                 final currentShiftAsync = ref.watch(currentShiftProvider(user!.id));
                 return Column(
                   children: [
                     // Shift Control
                     Card(
                       color: Colors.blue[50],
                       margin: const EdgeInsets.only(bottom: 16),
                       child: Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: Column(
                           children: [
                             Text("Shift Status: ${currentShiftAsync.value != null ? 'ON DUTY' : 'OFF DUTY'}", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                             const SizedBox(height: 8),
                             if (currentShiftAsync.value != null)
                                 Text("Started: ${DateTime.parse(currentShiftAsync.value!['check_in_time']).toLocal()}"),
                             const SizedBox(height: 16),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 ElevatedButton.icon(
                                   onPressed: () async {
                                     if (currentShiftAsync.value == null) {
                                       await ref.read(adminRepositoryProvider).checkIn(user.id);
                                     } else {
                                       await ref.read(adminRepositoryProvider).checkOut(user.id);
                                     }
                                     ref.invalidate(currentShiftProvider(user.id));
                                   },
                                   icon: Icon(currentShiftAsync.value != null ? Icons.stop : Icons.play_arrow),
                                   label: Text(currentShiftAsync.value != null ? 'Check Out' : 'Check In'),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: currentShiftAsync.value != null ? Colors.red : Colors.green,
                                     foregroundColor: Colors.white,
                                   ),
                                 ),
                               ],
                             )
                           ],
                         ),
                       ),
                     ),
                     
                     // Driver Vehicle & Docs
                     Card(
                       margin: const EdgeInsets.only(bottom: 16),
                       child: ListTile(
                         leading: const Icon(Icons.drive_eta, color: Colors.indigo),
                         title: const Text('Vehicle & Documents'),
                         subtitle: const Text('Manage DL, RC, and Car details'),
                         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                         onTap: () {
                           _showDriverDetailsDialog(context, ref, user.id, user.userMetadata);
                         },
                       ),
                     ),
                   ],
                 );
              }
            ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            onTap: () => _showEditProfileDialog(fullName),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
            title: const Text('My Wallet'),
            onTap: () => context.push('/wallet'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}

final userReviewsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  return ref.read(rideRepositoryProvider).getUserReviews(userId);
});

final currentShiftProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  return ref.read(adminRepositoryProvider).getCurrentShift(userId);
});
