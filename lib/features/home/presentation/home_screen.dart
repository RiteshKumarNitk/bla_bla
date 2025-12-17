import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bla_bla/features/auth/data/auth_repository_impl.dart';
import 'package:bla_bla/features/ride/data/ride_repository.dart';
import 'package:bla_bla/features/ride/domain/ride_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _departureController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _searchRides() {
    if (_departureController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter origin and destination')),
      );
      return;
    }
    
    context.push('/search', extra: {
      'origin': _departureController.text,
      'destination': _destinationController.text,
      'date': _selectedDate,
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final userRole = user?.userMetadata?['role'] ?? 'customer';
    final isDriver = userRole == 'driver' || userRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('BlaBla Clone', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header / Hero Section
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?q=80&w=1000&auto=format&fit=crop'), // Placeholder travel image
                    fit: BoxFit.cover,
                    opacity: 0.3,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Where do you want to go?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Search Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _departureController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.circle_outlined),
                            hintText: 'Leaving from',
                            border: InputBorder.none,
                          ),
                        ),
                        const Divider(),
                        TextField(
                          controller: _destinationController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.location_on_outlined),
                            hintText: 'Going to',
                            border: InputBorder.none,
                          ),
                        ),
                        const Divider(),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.grey),
                                const SizedBox(width: 12),
                                Text(
                                  '${_selectedDate.toLocal()}'.split(' ')[0],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                         const Divider(),
                         // Passenger Count (Simplified)
                         const Padding(
                           padding: EdgeInsets.symmetric(vertical: 12),
                           child: Row(
                             children: [
                               Icon(Icons.person_outline, color: Colors.grey),
                               SizedBox(width: 12),
                               Text('1 Passenger', style: TextStyle(fontSize: 16)),
                             ],
                           ),
                         ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _searchRides,
                            child: const Text('Search'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recently Published', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () {
                         context.push('/search', extra: {
                            'origin': '',
                            'destination': '',
                            'date': DateTime.now(),
                          });
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              SizedBox(
                height: 200, // Horizontal list height
                child: Consumer(
                  builder: (context, ref, child) {
                    final ridesAsync = ref.watch(nearbyRidesProvider);
                    
                    return ridesAsync.when(
                      data: (rides) {
                        if (rides.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No rides available right now.'),
                          );
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: rides.length,
                          itemBuilder: (context, index) {
                             final ride = rides[index];
                             return Container(
                               width: 160,
                               margin: const EdgeInsets.symmetric(horizontal: 8),
                               child: Card(
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                 elevation: 3,
                                 child: InkWell(
                                   onTap: () {
                                      context.push('/ride-detail', extra: ride);
                                   },
                                   child: Padding(
                                     padding: const EdgeInsets.all(12),
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text(
                                           '${ride.origin} → ${ride.destination}', 
                                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                           maxLines: 1, overflow: TextOverflow.ellipsis,
                                         ),
                                         const SizedBox(height: 4),
                                         Text(ride.departureTime.toString().split(' ')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                         const Spacer(),
                                         Text('₹${ride.price.toInt()}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                                         const SizedBox(height: 4),
                                         Row(
                                           children: [
                                             const Icon(Icons.person, size: 16, color: Colors.grey),
                                             const SizedBox(width: 4),
                                             Expanded(child: Text(ride.driverName ?? 'Driver', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                           ],
                                         )
                                       ],
                                     ),
                                   ),
                                 ),
                               ),
                             );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: isDriver ? FloatingActionButton.extended(
        onPressed: () {
          // Navigate to publish ride
          context.push('/publish');
        },
        label: const Text('Publish a Ride'),
        icon: const Icon(Icons.add_circle_outline),
      ) : null,
    );
  }
}
