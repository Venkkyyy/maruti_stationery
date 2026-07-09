import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppMode { customer, admin }

final appModeProvider = Provider<AppMode>((ref) => AppMode.customer);
