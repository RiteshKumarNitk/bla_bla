import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/auth/domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(Supabase.instance.client);
});

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<AuthResponse> signUpWithEmailPassword(String email, String password, {Map<String, dynamic>? data}) async {
    return await _supabase.auth.signUp(email: email, password: password, data: data);
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  @override
  Future<void> updateProfile({String? name}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (name != null) {
      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': name}),
      );
      try {
        await _supabase.from('profiles').update({'full_name': name}).eq('id', user.id);
      } catch (e) {
        // Handle error silently or log
      }
    }
  }
}
