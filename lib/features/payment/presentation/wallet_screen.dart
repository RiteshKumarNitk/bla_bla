import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/payment/data/wallet_repository.dart';
import 'package:bla_bla/features/auth/data/auth_repository_impl.dart';

final myWalletProvider = FutureProvider.autoDispose((ref) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) throw Exception("User not logged in");
  return ref.read(walletRepositoryProvider).getWallet(user.id);
});

final myTransactionsProvider = FutureProvider.autoDispose((ref) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) return <Map<String, dynamic>>[];
  return ref.read(walletRepositoryProvider).getTransactions(user.id);
});

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(myWalletProvider);
    final transactionsAsync = ref.watch(myTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wallet"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Colors.indigo,
            child: Column(
              children: [
                const Text("Total Balance", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                walletAsync.when(
                  data: (w) => Text("₹${(w['balance'] as num).toStringAsFixed(2)}", 
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  loading: () => const CircularProgressIndicator(color: Colors.white),
                  error: (_,__) => const Text("Error", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Withdrawal Request Sent!")));
                  }, 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.indigo),
                  child: const Text("Withdraw Money"),
                )
              ],
            ),
          ),
          
          // Transactions List
          Expanded(
            child: transactionsAsync.when(
              data: (txs) {
                if(txs.isEmpty) return const Center(child: Text("No transactions yet"));
                return ListView.builder(
                  itemCount: txs.length,
                  itemBuilder: (context, index) {
                    final tx = txs[index];
                    final isPositive = (tx['amount'] as num) > 0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPositive ? Colors.green[100] : Colors.red[100],
                        child: Icon(isPositive ? Icons.arrow_downward : Icons.arrow_upward, 
                            color: isPositive ? Colors.green : Colors.red),
                      ),
                      title: Text(tx['description'] ?? 'Transaction'),
                      subtitle: Text((tx['created_at'] as String).substring(0, 10)),
                      trailing: Text(
                        "${isPositive ? '+' : ''}₹${tx['amount']}",
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e,s) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
    );
  }
}
