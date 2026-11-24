import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/app_mode_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _textFadeAnim;
  late Animation<Offset> _textSlideAnim;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutCubic,
      ),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );
    _textSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Sequence animations smoothly
    _logoController.forward().then((_) {
      if (mounted) _textController.forward();
    });

    // Execute application initialization flow
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Graceful animation delay
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final userModel = await ref.read(currentUserModelProvider.future);
        if (!mounted) return;

        final appMode = ref.read(appModeProvider);

        if (userModel == null ||
            userModel.name.trim().isEmpty ||
            userModel.phone.trim().isEmpty) {
          context.go('/auth/complete-profile');
        } else if (appMode == AppMode.admin) {
          context.go('/admin');
        } else {
          context.go('/home');
        }
      } catch (e) {
        // Fallback for offline or connection issues
        if (mounted) {
          final appMode = ref.read(appModeProvider);
          if (appMode == AppMode.admin) {
            context.go('/admin');
          } else {
            context.go('/home');
          }
        }
      }
    } else {
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const warmCream = Color(0xFFF8F4E9);
    const ivory = Color(0xFFFFFDF6);
    const royalBlue = Color(0xFF173A9B);
    const primaryOrange = Color(0xFFFF681F);
    const darkNavy = Color(0xFF0F172A);
    const mutedSlate = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: warmCream,
      body: Stack(
        children: [
          // ── Subtle Ambient Radial Gradient Background ─────────────
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.1),
                radius: 1.1,
                colors: [
                  ivory,
                  warmCream,
                ],
                stops: [0.3, 1.0],
              ),
            ),
          ),

          // ── Subtle Minimal Decorative Stationery Accents ──────────
          // Top-right soft ambient circle
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: royalBlue.withValues(alpha: 0.035),
              ),
            ),
          ),
          // Bottom-left soft ambient circle
          Positioned(
            bottom: -70,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryOrange.withValues(alpha: 0.03),
              ),
            ),
          ),
          // Subtle stationery notebook outline graphic (minimal, low opacity)
          Positioned(
            top: 100,
            left: 28,
            child: Opacity(
              opacity: 0.04,
              child: Icon(
                Icons.auto_stories_rounded,
                size: 72,
                color: royalBlue,
              ),
            ),
          ),
          Positioned(
            bottom: 140,
            right: 32,
            child: Opacity(
              opacity: 0.04,
              child: Icon(
                Icons.edit_note_rounded,
                size: 64,
                color: royalBlue,
              ),
            ),
          ),

          // ── Center Brand Logo & Typography ────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Prominent Blue "M" Symbol Badge
                ScaleTransition(
                  scale: _scaleAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1E42BA),
                            royalBlue,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: royalBlue.withValues(alpha: 0.28),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'M',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Animated Brand Title & Tagline
                SlideTransition(
                  position: _textSlideAnim,
                  child: FadeTransition(
                    opacity: _textFadeAnim,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final isAdminMode =
                            ref.read(appModeProvider) == AppMode.admin;

                        return Column(
                          children: [
                            Text(
                              isAdminMode
                                  ? 'Maruti Admin'
                                  : 'Maruti Stationery',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: darkNavy,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: primaryOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isAdminMode
                                      ? 'ADMINISTRATION PORTAL'
                                      : 'STATIONERY & SUPPLIES',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: mutedSlate,
                                    letterSpacing: 2.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Loading Indicator & Quality Promise ────────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textFadeAnim,
              child: Column(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        primaryOrange.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Quality Supplies for Everyday Growth',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: mutedSlate.withValues(alpha: 0.8),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
