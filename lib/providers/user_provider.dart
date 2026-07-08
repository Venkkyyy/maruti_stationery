import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

part 'user_provider.g.dart';

@riverpod
Future<UserModel?> currentUserModel(Ref ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  return ref.watch(authServiceProvider).getUser(user.uid);
}
