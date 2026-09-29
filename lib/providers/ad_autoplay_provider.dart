import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kWifiOnlyKey = 'ad_wifi_only_autoplay';

/// Notifier that persists the "Wi-Fi only autoplay" preference.
class AdAutoplayNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Kick off async load; return safe default while loading
    _load();
    return true; // default: Wi-Fi only
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kWifiOnlyKey) ?? true;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWifiOnlyKey, value);
  }
}

/// True = only autoplay on Wi-Fi. Default: true (safe for mobile data).
final adWifiOnlyProvider =
    NotifierProvider<AdAutoplayNotifier, bool>(AdAutoplayNotifier.new);
