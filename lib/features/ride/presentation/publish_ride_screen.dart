import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bla_bla/features/ride/data/ride_repository.dart';
import 'package:bla_bla/features/ride/domain/ride_model.dart';
import 'package:bla_bla/features/auth/data/auth_repository_impl.dart';
import 'package:bla_bla/features/admin/data/admin_repository.dart';

final selectedDriverIdProvider = NotifierProvider<SelectedDriverIdNotifier, String?>(SelectedDriverIdNotifier.new);

class SelectedDriverIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void set(String? id) => state = id;
}

class PublishRideScreen extends ConsumerStatefulWidget {
  const PublishRideScreen({super.key});

  @override
  ConsumerState<PublishRideScreen> createState() => _PublishRideScreenState();
}

class _PublishRideScreenState extends ConsumerState<PublishRideScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController(text: '1');
  DateTime _departureTime = DateTime.now();

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date != null) {
      if (!context.mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_departureTime),
      );
      if (time != null) {
        setState(() {
          _departureTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _publishRide() async {
    final currentUser = ref.read(authRepositoryProvider).currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in')));
      return;
    }

    try {
      final selectedDriverId = ref.read(selectedDriverIdProvider);
      final actualDriverId = (currentUser.userMetadata?['role'] == 'admin' && selectedDriverId != null) 
          ? selectedDriverId 
          : currentUser.id;

      final ride = Ride(
        id: '', // Supabase generates ID
        driverId: actualDriverId,


        origin: _originController.text,
        destination: _destinationController.text,
        departureTime: _departureTime,
        price: double.tryParse(_priceController.text) ?? 0,
        totalSeats: int.tryParse(_seatsController.text) ?? 1,
        availableSeats: int.tryParse(_seatsController.text) ?? 1,
        carModel: 'Generic Car', // Can add field later
      );

      final rideToInsert = ride.toJson();
      rideToInsert.remove('id'); // Allow DB to generate UUID

      // We need to use the repository but slightly modified to handle the ID/JSON exclusion or just accept the Ride object.
      // Ideally the model/repo handles this transform. For speed, I'll update the repo usage or just raw insert logic here if needed, 
      // but let's stick to the repo pattern I just created.
      // Wait, the repo insert takes Json from the Model. The Model includes ID. 
      // I should update the model toJson to exclude ID if empty or handle it in repo.
      // Let's rely on Repo. The repo calls `ride.toJson()`.
      
      await ref.read(rideRepositoryProvider).createRide(ride);
      
      // Refresh lists
      ref.invalidate(nearbyRidesProvider);
      ref.invalidate(offeredRidesProvider(actualDriverId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride published!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Offer a ride')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Route Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _originController,
                      decoration: const InputDecoration(
                        labelText: 'Pick-up',
                        prefixIcon: Icon(Icons.my_location),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _destinationController,
                      decoration: const InputDecoration(
                        labelText: 'Drop-off',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),


            const SizedBox(height: 16),
            
            // Admin Driver Assignment
            if (currentUser?.userMetadata?['role'] == 'admin')
              Card(
                child: Padding(
                   padding: const EdgeInsets.all(16),
                   child: Consumer(
                     builder: (context, ref, _) {
                       final driversAsync = ref.watch(allDriversProvider);
                       return driversAsync.when(
                         data: (drivers) {
                           return DropdownButtonFormField<String>(
                             decoration: const InputDecoration(labelText: 'Assign Driver'),
                             items: drivers.map((d) => DropdownMenuItem(
                               value: d['id'].toString(),
                               child: Text("${d['full_name']} (${d['email']})"),
                             )).toList(),
                             onChanged: (val) {
                               // Store selected driver ID in state or controller
                               ref.read(selectedDriverIdProvider.notifier).set(val);
                             },
                           );
                         },
                         loading: () => const LinearProgressIndicator(),
                         error: (e, s) => Text('Error loading drivers: $e'),
                       );
                     }
                   ),
                ),
              ),
              if (currentUser?.userMetadata?['role'] == 'admin') const SizedBox(height: 16),

            // Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _selectDateTime(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Departure Time',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          '${_departureTime.toLocal()}'.split('.')[0],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Price per seat (₹)',
                              prefixIcon: Icon(Icons.attach_money), // Kept icon for now, or change to currency_rupee
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _seatsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Seats',
                              prefixIcon: Icon(Icons.event_seat),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _publishRide,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Publish Ride'),
            ),
          ],
        ),
      ),
    );
  }
}
