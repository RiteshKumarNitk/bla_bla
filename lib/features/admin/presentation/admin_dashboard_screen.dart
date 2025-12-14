import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/ride/data/ride_repository.dart';
import 'package:bla_bla/features/admin/data/admin_repository.dart';

// Provider to fetch all rides (admin only)
final allRidesProvider = FutureProvider((ref) async{
  final repo = ref.read(rideRepositoryProvider);
  return repo.searchRides('', '', DateTime.now()); 
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.redAccent,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Rides"),
              Tab(text: "Drivers"),
              Tab(text: "Offers"),
              Tab(text: "Customers"),
              Tab(text: "Stats"),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                ref.invalidate(allRidesProvider);
                ref.invalidate(allDriversProvider);
                ref.invalidate(fleetStatsProvider);
                ref.invalidate(allCustomersProvider); // New
                ref.invalidate(allPromotionsProvider); // New
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _RidesList(),
            _DriversList(),
            _EngagementPanel(),
            _CustomersList(),
            _FleetStats(),
          ],
        ),
      ),
    );
  }
}

class _RidesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(allRidesProvider);
    return ridesAsync.when(
      data: (rides) => ListView.builder(
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.local_taxi, color: Colors.white)),
              title: Text("${ride.origin} -> ${ride.destination}"),
              subtitle: Text("Driver: ${ride.driverId}\nPrice: ₹${ride.price}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete not implemented yet")));
                },
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
    );
  }
}

class _DriversList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(allDriversProvider);
    return driversAsync.when(
      data: (drivers) => ListView.builder(
        itemCount: drivers.length,
        itemBuilder: (context, index) {
          final driver = drivers[index];
          final isVerified = driver['is_verified'] ?? false;
          final hoursAsync = ref.watch(driverHoursProvider(driver['id']));
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: isVerified ? Colors.green : Colors.grey,
                child: Icon(isVerified ? Icons.check : Icons.person, color: Colors.white),
              ),
              title: Text(driver['full_name'] ?? 'Unknown Driver'),
              subtitle: hoursAsync.when(
                  data: (h) => Text("Total Hours: ${h.toStringAsFixed(1)} hrs"),
                  loading: () => const Text("Calculating hours..."),
                  error: (_,__) => const Text("Hours: N/A")
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${driver['email'] ?? 'N/A'}"),
                      Text("DL: ${driver['dl_number'] ?? 'Pending'}"),
                      Text("Aadhar: ${driver['aadhar_number'] ?? 'N/A'}"),
                      Text("Vehicle: ${driver['vehicle_details'] ?? 'N/A'}"),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                             onPressed: () {
                               // Send Bonus Notification
                               ref.read(adminRepositoryProvider).sendNotification(
                                 driver['id'], 
                                 "Bonus Earned!", 
                                 "You have earned a ₹200 bonus for your performance."
                               );
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bonus sent!")));
                             },
                             child: const Text("Send Bonus"),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                                await ref.read(adminRepositoryProvider).verifyDriver(driver['id'], !isVerified);
                                ref.invalidate(allDriversProvider);
                            },
                            icon: Icon(isVerified ? Icons.close : Icons.check),
                            label: Text(isVerified ? "Un-verify" : "Verify Driver"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: isVerified ? Colors.red : Colors.green,
                                foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Confirm Deletion
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Delete Driver?"),
                                  content: const Text("This cannot be undone."),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                await ref.read(adminRepositoryProvider).deleteUser(driver['id']);
                                ref.invalidate(allDriversProvider);
                              }
                            },
                             icon: const Icon(Icons.delete, color: Colors.white),
                             label: const Text("Delete"),
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
    );
  }
}

class _CustomersList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(allCustomersProvider);
    return customersAsync.when(
      data: (customers) => ListView.builder(
        itemCount: customers.length,
        itemBuilder: (context, index) {
            final cust = customers[index];
            return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(cust['full_name'] ?? 'Customer'),
                subtitle: Text(cust['email'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.notifications_active, color: Colors.blue),
                        onPressed: () {
                            ref.read(adminRepositoryProvider).sendNotification(cust['id'], "Special Offer", "Use code WELCOME200");
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Offer sent!")));
                        },
                    ),
                    IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                             final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Delete Customer?"),
                                  content: const Text("This cannot be undone."),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                await ref.read(adminRepositoryProvider).deleteUser(cust['id']);
                                ref.invalidate(allCustomersProvider);
                              }
                        },
                    ),
                  ],
                ),
            );
        },
      ), 
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e,s) => Text("Error: $e"),
    );
  }
}

class _EngagementPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = ref.watch(allPromotionsProvider);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Create New Promo Code"),
            onPressed: () {
                // Simplified creation for MVP
                ref.read(adminRepositoryProvider).createPromotion("FLASH50", "Flash Sale 50 Off", 50.0, "all");
                ref.invalidate(allPromotionsProvider);
            },
          ),
          const Divider(),
          const Text("Active Promotions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: promotionsAsync.when(
                data: (promos) => ListView.builder(
                    itemCount: promos.length,
                    itemBuilder: (ctx, i) => Card(
                        child: ListTile(
                            title: Text(promos[i]['code'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            subtitle: Text("${promos[i]['description']} (Max ₹${promos[i]['discount_amount']})"),
                            trailing: Text(promos[i]['target_role'].toUpperCase()),
                        ),
                    ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e,s) => Text("Error: $e"),
            ),
          )
        ],
      ),
    );
  }
}

final fleetStatsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(adminRepositoryProvider).getFleetStats();
});

class _FleetStats extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(fleetStatsProvider);
    
    return statsAsync.when(
      data: (stats) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _StatCard("Total Drivers", "${stats['total_drivers']}", Colors.blue),
            _StatCard("Active Shifts", "${stats['active_drivers']}", Colors.green),
            _StatCard("Rides Today", "${stats['rides_today']}", Colors.orange),
            _StatCard("Occupancy Rate", "${stats['occupancy_rate']}%", Colors.purple),
            _StatCard("Booked Seats", "${stats['booked_seats']}", Colors.redAccent),
            _StatCard("Total Capacity", "${stats['total_seats']}", Colors.teal),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Error: $e")),
    );
  }
  
  Widget _StatCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }
}
