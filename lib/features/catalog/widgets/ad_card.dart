import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/ad_model.dart';
import '../../../providers/ads_provider.dart';
import '../../../providers/ad_autoplay_provider.dart';

/// Full-width in-feed native video ad card.
///
/// Behaviour:
/// - Autoplays muted when ≥ 50% visible AND connectivity allows (respects
///   the Wi-Fi-only autoplay preference).
/// - Pauses when scrolled out of view.
/// - Loops video.
/// - On video init failure: shows thumbnail (or grey box) + CTA still tappable.
/// - Shows "Sponsored" badge (top-left) for transparency.
/// - Logs impression once per session; logs click on CTA tap.
class AdCard extends ConsumerStatefulWidget {
  final AdModel ad;

  /// Tracks which ad IDs have had impressions logged this session.
  /// Using a local Set means one impression per session — intentional
  /// standard behaviour, not a bug.
  final Set<String> loggedImpressions;

  const AdCard({
    super.key,
    required this.ad,
    required this.loggedImpressions,
  });

  @override
  ConsumerState<AdCard> createState() => _AdCardState();
}

class _AdCardState extends ConsumerState<AdCard> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _failed = false;      // true if video init threw an error
  bool _muted = true;
  bool _initStarted = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _maybeInitVideo();
  }

  Future<void> _maybeInitVideo() async {
    if (_initStarted || widget.ad.videoUrl.isEmpty) return;
    _initStarted = true;

    // Check connectivity before creating the controller
    final wifiOnly = ref.read(adWifiOnlyProvider);
    if (wifiOnly) {
      try {
        final results = await InternetAddress.lookup('example.com');
        // InternetAddress.lookup works over any network; for Wi-Fi check
        // we use the NetworkInterface approach below.
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
        );
        final isOnWifi = interfaces.any((iface) =>
            iface.name.toLowerCase().contains('wlan') ||
            iface.name.toLowerCase().contains('en0') ||
            iface.name.toLowerCase().contains('wifi'));
        if (!isOnWifi && results.isNotEmpty) {
          // On mobile data — skip autoplay init. Card shows thumbnail + CTA.
          if (mounted) setState(() => _failed = false); // thumbnail shown
          return;
        }
      } catch (_) {
        // Can't determine connection type — skip init to save data
        return;
      }
    }

    await _initController();
  }

  Future<void> _initController() async {
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(widget.ad.videoUrl),
    );
    ctrl.setVolume(0);
    ctrl.setLooping(true);
    try {
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      _controller = ctrl;
      setState(() => _initialized = true);
      // If the card is already visible, start playing immediately
      if (_isVisible) ctrl.play();
    } catch (_) {
      ctrl.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final fraction = info.visibleFraction;
    _isVisible = fraction >= 0.5;

    if (_initialized && _controller != null) {
      if (_isVisible) {
        if (!_controller!.value.isPlaying) _controller!.play();
      } else {
        if (_controller!.value.isPlaying) _controller!.pause();
      }
    }

    // Log impression once per session
    if (_isVisible && !widget.loggedImpressions.contains(widget.ad.id)) {
      widget.loggedImpressions.add(widget.ad.id);
      logAdImpression(widget.ad.id);
    }
  }

  void _onCtaTap(BuildContext context) {
    logAdClick(widget.ad.id);
    final ad = widget.ad;
    switch (ad.ctaType) {
      case AdCtaType.product:
        context.push('/catalog/product/${ad.ctaValue}');
      case AdCtaType.category:
        context.go('/catalog?categoryId=${ad.ctaValue}');
      case AdCtaType.collection:
        final title = Uri.encodeComponent(ad.ctaLabel);
        context.push('/banner-products?tag=${ad.ctaValue}&title=$title');
      case AdCtaType.url:
        launchUrl(Uri.parse(ad.ctaValue),
            mode: LaunchMode.externalApplication);
      case AdCtaType.none:
        break;
    }
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() => _muted = !_muted);
    _controller!.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final wifiOnly = ref.watch(adWifiOnlyProvider);

    return Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Video / Thumbnail area ──────────────────────────────────
              Expanded(
                child: VisibilityDetector(
                  key: Key('ad_${widget.ad.id}'),
                  onVisibilityChanged: _onVisibilityChanged,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Base: thumbnail or grey box (always present as
                      // fallback — covers load state AND failure state)
                      if (widget.ad.thumbnailUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: widget.ad.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              Container(color: colors.surfaceGrey),
                        )
                      else
                        Container(color: colors.surfaceGrey),

                      // Video layer — only shown when successfully initialized
                      if (_initialized && _controller != null)
                        SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _controller!.value.size.width,
                              height: _controller!.value.size.height,
                              child: VideoPlayer(_controller!),
                            ),
                          ),
                        ),

                      // Wi-Fi only hint — shown when autoplay was skipped
                      if (!_initialized && !_failed && wifiOnly)
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.wifi_off_rounded,
                                    color: Colors.white70, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Video plays on Wi-Fi',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Play icon on thumbnail when not playing (not failed)
                      if (!_initialized && !_failed && !wifiOnly)
                        const Center(
                          child: Icon(Icons.play_circle_outline_rounded,
                              color: Colors.white70, size: 48),
                        ),

                      // "Sponsored" badge — top left
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.60),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Sponsored',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),

                      // Mute/Unmute — top right (only when video playing)
                      if (_initialized)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _toggleMute,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _muted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── CTA bar — always shown when hasCta, even if video failed ──
              if (widget.ad.hasCta)
                InkWell(
                  onTap: () => _onCtaTap(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primary.withValues(alpha: 0.08),
                          colors.primary.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.ad.ctaLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.ad.ctaLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
  }
}
