import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

part 'user_provider.g.dart';

@riverpod
Future<UserModel?> currentUserModel(Ref ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.watch(authServiceProvider).getUser(user.uid);
}
