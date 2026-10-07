import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display / Headlines ──────────────────────────────────────
  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.outfit(
    fontSize: 26, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.25,
  );

  static TextStyle headlineLarge = GoogleFonts.outfit(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );

  static TextStyle headlineMedium = GoogleFonts.outfit(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.35,
  );

  static TextStyle headlineSmall = GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ─────────────────────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.55,
  );

  static TextStyle bodyMedium = GoogleFonts.outfit(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.55,
  );

  static TextStyle bodySmall = GoogleFonts.outfit(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );

  // ── Labels / Chips ───────────────────────────────────────────
  static TextStyle labelLarge = GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.outfit(
    fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.outfit(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.8,
  );

  // ── Price ────────────────────────────────────────────────────
  static TextStyle priceMain = GoogleFonts.outfit(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static TextStyle priceMRP = GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    decoration: TextDecoration.lineThrough,
  );

  // ── Buttons ──────────────────────────────────────────────────
  static TextStyle buttonLarge = GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.3,
  );

  static TextStyle buttonMedium = GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // ── AppBar ───────────────────────────────────────────────────
  static TextStyle appBarTitle = GoogleFonts.outfit(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  // ── Section Headers — Blinkit style ──────────────────────────
  static TextStyle sectionTitle = GoogleFonts.outfit(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.2,
  );

  static TextStyle sectionLink = GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}
