import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/auth/data/auth_repository_impl.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => 
      ref.read(authRepositoryProvider).signInWithEmailPassword(email, password));
  }

  Future<void> signUp(String email, String password, {String role = 'customer'}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => 
      ref.read(authRepositoryProvider).signUpWithEmailPassword(email, password, data: {'role': role}));
  }
  
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).signOut());
  }
}
