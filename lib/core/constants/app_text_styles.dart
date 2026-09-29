import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display / Headlines ──────────────────────────────────────
  static TextStyle displayLarge = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.25,
  );

  static TextStyle headlineLarge = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );

  static TextStyle headlineMedium = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.35,
  );

  static TextStyle headlineSmall = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ─────────────────────────────────────────────────────
  static TextStyle bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.55,
  );

  static TextStyle bodyMedium = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.55,
  );

  static TextStyle bodySmall = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );

  // ── Labels / Chips ───────────────────────────────────────────
  static TextStyle labelLarge = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.8,
  );

  // ── Price ────────────────────────────────────────────────────
  static TextStyle priceMain = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static TextStyle priceMRP = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    decoration: TextDecoration.lineThrough,
  );

  // ── Buttons ──────────────────────────────────────────────────
  static TextStyle buttonLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.3,
  );

  static TextStyle buttonMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // ── AppBar ───────────────────────────────────────────────────
  static TextStyle appBarTitle = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  // ── Section Headers — Playfair Display for premium branded look ───────────
  static TextStyle sectionTitle = GoogleFonts.playfairDisplay(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
    height: 1.2,
  );

  static TextStyle sectionLink = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}
