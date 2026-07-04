import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/auth_service.dart';

part 'auth_provider.g.dart';

@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}

@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return ref.watch(authServiceProvider).authStateChanges;
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> sendOTP(String phone, {
    required Function(String) onCodeSent,
    required Function(String) onError,
    required Function(PhoneAuthCredential) onAutoVerified,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).sendOTP(
        phoneNumber: phone,
        onCodeSent: onCodeSent,
        onError: onError,
        onAutoVerified: onAutoVerified,
      );
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> verifyOTP(String verificationId, String otp) async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).verifyOTP(
        verificationId: verificationId,
        otp: otp,
      );
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}
