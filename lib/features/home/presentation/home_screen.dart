import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bla_bla/features/auth/data/auth_repository_impl.dart';

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
