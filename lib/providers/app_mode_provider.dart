import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppMode { customer, admin, delivery }

final appModeProvider = Provider<AppMode>((ref) => AppMode.customer);
