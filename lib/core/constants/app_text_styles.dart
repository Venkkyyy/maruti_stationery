import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display / Headlines ──────────────────────────────────────
  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 26, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.25,
  );

  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );

  static TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.35,
  );

  static TextStyle headlineSmall = GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ─────────────────────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.55,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.55,
  );

  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );

  // ── Labels / Chips ───────────────────────────────────────────
  static TextStyle labelLarge = GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.8,
  );

  // ── Price ────────────────────────────────────────────────────
  static TextStyle priceMain = GoogleFonts.poppins(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static TextStyle priceMRP = GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    decoration: TextDecoration.lineThrough,
  );

  // ── Buttons ──────────────────────────────────────────────────
  static TextStyle buttonLarge = GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.3,
  );

  static TextStyle buttonMedium = GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // ── AppBar ───────────────────────────────────────────────────
  static TextStyle appBarTitle = GoogleFonts.poppins(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  // ── Section Headers ──────────────────────────────────────────
  static TextStyle sectionTitle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.2,
  );

  static TextStyle sectionLink = GoogleFonts.poppins(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}
