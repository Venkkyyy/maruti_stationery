import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Reference Brand Colors (Exact from Screenshot) ────────────
  static const Color primary        = Color(0xFFEE6A2B); // Vibrant Orange
  static const Color primaryDark    = Color(0xFFD85718);
  static const Color primaryLight   = Color(0xFFFFEFE6);
  static const Color primarySurface = Color(0xFFFFEFE6);
  static const Color royalBlue      = Color(0xFF1A38C9); // Reference Royal Blue
  static const Color royalBlueDark  = Color(0xFF142C9D);

  // ── Reference Canvas & Cards ──────────────────────────────────
  static const Color background   = Color(0xFFFAF7EE); // Exact warm cream background
  static const Color surface      = Color(0xFFFFFFFF); // Pure white cards
  static const Color surfaceWarm  = Color(0xFFF6F3EA); // Soft warm container
  static const Color surfaceGrey  = Color(0xFFF0ECE1);
  static const Color divider      = Color(0xFFE8E3D7); // Reference warm border
  static const Color border       = Color(0xFFE8E3D7);

  // ── Text ─────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF111827); // Deep slate from reference
  static const Color navyText      = Color(0xFF0F172A); // Deep navy for titles and headers
  static const Color textSecondary = Color(0xFF6B7280); // Cool grey subtitle
  static const Color textHint      = Color(0xFF9CA3AF); // Search placeholder
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Semantic ─────────────────────────────────────────────────
  static const Color success     = Color(0xFF22C55E);
  static const Color successLight= Color(0xFFDCFCE7);
  static const Color error       = Color(0xFFEF4444);
  static const Color errorLight  = Color(0xFFFEE2E2);
  static const Color warning     = Color(0xFFF59E0B);
  static const Color warningLight= Color(0xFFFEF3C7);

  // ── Special ──────────────────────────────────────────────────
  static const Color badge        = Color(0xFFEF4444);
  static const Color shimmerBase  = Color(0xFFE8E3D7);
  static const Color shimmerHigh  = Color(0xFFFAF7EE);
  static const Color inkDark      = Color(0xFF0F172A);
}
