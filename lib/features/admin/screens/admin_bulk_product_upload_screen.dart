import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product_model.dart';
import '../../../models/bulk_import_batch_model.dart';
import '../../../providers/categories_provider.dart';
import '../../../services/admin_excel_service.dart';
import '../../../services/admin_zip_image_service.dart';

class AdminBulkProductUploadScreen extends ConsumerStatefulWidget {
  const AdminBulkProductUploadScreen({super.key});

  @override
  ConsumerState<AdminBulkProductUploadScreen> createState() => _AdminBulkProductUploadScreenState();
}

class _AdminBulkProductUploadScreenState extends ConsumerState<AdminBulkProductUploadScreen>
    with SingleTickerProviderStateMixin {
  final AdminExcelService _excelService = AdminExcelService();
  final AdminZipImageService _zipService = AdminZipImageService();
  late TabController _tabController;

  // ── Tab 1: Excel State ──
  bool _isProcessingFile = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _selectedFileName;
  BulkImportResult? _importResult;
  final Map<String, String> _duplicateResolutions = {};

  // ── Tab 2: ZIP Photos State ──
  bool _isProcessingZip = false;
  bool _isUploadingZip = false;
  double _zipUploadProgress = 0.0;
  String _zipUploadStatusText = '';
  String? _selectedZipName;
  ZipMatchResult? _zipResult;
  bool _replaceExistingPhotos = true;

  // ── Tab 3: Rollback State ──
  bool _isRollingBack = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 1: EXCEL HANDLERS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _handleDownloadTemplate() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating sample Excel template...'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _excelService.downloadSampleProductTemplate();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate template: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handlePickFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final fileBytes = await file.readAsBytes();
      if (fileBytes.isEmpty) {
        throw Exception('Could not read file data or file is empty. Please try again.');
      }

      setState(() {
        _isProcessingFile = true;
        _selectedFileName = file.name;
        _importResult = null;
        _duplicateResolutions.clear();
      });

      final categories = ref.read(categoriesProvider).value ?? [];

      final parsed = await _excelService.parseProductFile(
        fileBytes: fileBytes,
        fileName: file.name,
        availableCategories: categories,
      );

      if (!mounted) return;

      for (final conflict in parsed.duplicates) {
        _duplicateResolutions[conflict.importedProduct.id] = 'replace';
      }

      setState(() {
        _isProcessingFile = false;
        _importResult = parsed;
      });

      if (parsed.validProducts.isEmpty && parsed.duplicates.isEmpty && parsed.hasErrors) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parsed.errors.first),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingFile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reading Excel: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyResolutionToAll(String choice) {
    if (_importResult == null) return;
    setState(() {
      for (final conflict in _importResult!.duplicates) {
        _duplicateResolutions[conflict.importedProduct.id] = choice;
      }
    });
  }

  Future<void> _handleCommitUpload() async {
    if (_importResult == null) return;

    final replaceCount = _importResult!.duplicates
        .where((c) => _duplicateResolutions[c.importedProduct.id] == 'replace')
        .length;
    final keepBothCount = _importResult!.duplicates
        .where((c) => _duplicateResolutions[c.importedProduct.id] == 'keep_both')
        .length;
    final totalToImport = _importResult!.validProducts.length + replaceCount + keepBothCount;

    if (totalToImport == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products selected for import. All duplicates were skipped.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Bulk Upload',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload summary to cloud catalog:',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Text('• New Products: ${_importResult!.validProducts.length}',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyText)),
            if (replaceCount > 0)
              Text('• Products to Replace: $replaceCount',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning)),
            if (keepBothCount > 0)
              Text('• Additional Duplicates (Keep Both): $keepBothCount',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
            if (_importResult!.autoCreatedCategories.isNotEmpty)
              Text('• Auto-creating ${_importResult!.autoCreatedCategories.length} Categories',
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.royalBlue, fontWeight: FontWeight.w600)),
            if (_importResult!.autoCreatedBrands.isNotEmpty)
              Text('• Auto-creating ${_importResult!.autoCreatedBrands.length} Brands',
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.royalBlue, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Upload Now', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final batch = await _excelService.commitBulkImport(
        fileName: _selectedFileName ?? 'Bulk_Import.xlsx',
        adminEmail: user?.email ?? 'admin@marutistationery.com',
        productsToCreate: _importResult!.validProducts,
        categoriesToCreate: _importResult!.autoCreatedCategories,
        brandsToCreate: _importResult!.autoCreatedBrands,
        duplicateResolutions: _duplicateResolutions,
        duplicateConflicts: _importResult!.duplicates,
        onProgress: (completed, all) {
          if (mounted) {
            setState(() {
              _uploadProgress = all > 0 ? completed / all : 1.0;
            });
          }
        },
      );

      if (!mounted) return;
      setState(() => _isUploading = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Products Uploaded!',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navyText),
              ),
              const SizedBox(height: 8),
              Text(
                'Successfully imported ${batch.totalCount} products into your cloud catalog.\n\nNow switch to the "Product Photos (.zip)" tab to upload their images in bulk!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _tabController.animateTo(1); // Jump to ZIP tab!
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.royalBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Upload Photos (.zip)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/admin/products');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('View Catalog', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint('Bulk upload error: $e\n$stack');
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 2: ZIP PHOTOS HANDLERS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _handlePickZip() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final fileBytes = await file.readAsBytes();
      if (fileBytes.isEmpty) {
        throw Exception('Could not read ZIP data or file is empty.');
      }

      setState(() {
        _isProcessingZip = true;
        _selectedZipName = file.name;
        _zipResult = null;
      });

      final parsed = await _zipService.parseZipArchive(fileBytes);

      if (!mounted) return;
      setState(() {
        _isProcessingZip = false;
        _zipResult = parsed;
      });

      if (parsed.matches.isEmpty && parsed.unmatched.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid product image folders found in this ZIP archive.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingZip = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reading ZIP: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleCommitZipUpload() async {
    if (_zipResult == null || _zipResult!.matches.isEmpty) return;

    final totalPhotos = _zipResult!.matches.fold(0, (sum, m) => sum + m.images.length);
    final totalProducts = _zipResult!.matches.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm ZIP Photo Upload',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText),
        ),
        content: Text(
          'Upload $totalPhotos photos to Cloudinary and link them to $totalProducts products in your catalog?\n\n'
          'Mode: ${_replaceExistingPhotos ? "Replace current photos" : "Add to existing photos"}\n\n'
          'A rollback batch will be created so you can undo this upload and delete photos from Cloudinary anytime.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Upload Now', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isUploadingZip = true;
      _zipUploadProgress = 0.0;
      _zipUploadStatusText = 'Preparing Cloudinary upload...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final batch = await _zipService.uploadZipImages(
        fileName: _selectedZipName ?? 'Photos_Upload.zip',
        adminEmail: user?.email ?? 'admin@marutistationery.com',
        matches: _zipResult!.matches,
        replaceExisting: _replaceExistingPhotos,
        onProgress: (pIdx, pTotal, photoIdx, photoTotal) {
          if (mounted) {
            setState(() {
              _zipUploadProgress = photoTotal > 0 ? photoIdx / photoTotal : 1.0;
              _zipUploadStatusText = 'Product $pIdx of $pTotal (Photo $photoIdx of $photoTotal)...';
            });
          }
        },
      );

      if (!mounted) return;
      setState(() => _isUploadingZip = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Photos Uploaded!',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navyText),
              ),
              const SizedBox(height: 8),
              Text(
                'Successfully linked ${batch.totalCount} products with ${batch.uploadedPhotosCount} photos in Cloudinary and your cloud catalog.\n\nA rollback batch was saved so you can revert this upload anytime.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _zipResult = null;
                          _selectedZipName = null;
                        });
                        _tabController.animateTo(2); // Jump to History & Rollback tab!
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('View History', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/admin/products');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('View Products', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingZip = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ZIP upload failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 3: ROLLBACK HANDLERS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _handleRollback(BulkImportBatchModel batch) async {
    final isPhoto = batch.isPhotoBatch;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isPhoto ? 'Rollback ZIP Photo Upload?' : 'Rollback Excel Import Batch?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.error),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to rollback batch "${batch.fileName}" imported on ${DateFormat('dd MMM yyyy, hh:mm a').format(batch.timestamp)}?',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyText),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cloud Actions on Rollback:',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error)),
                  const SizedBox(height: 4),
                  if (isPhoto) ...[
                    Text(
                      '• All ${batch.uploadedPhotosCount} photos uploaded in this batch will be permanently DELETED from Cloudinary cloud.',
                      style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.navyText),
                    ),
                    Text(
                      '• Photo galleries for ${batch.totalCount} products will be RESTORED to their exact previous state in Firestore and Algolia.',
                      style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.navyText),
                    ),
                  ] else ...[
                    Text(
                      '• ${batch.createdProductIds.length} newly created products will be permanently DELETED from Firestore, Algolia, and Cloudinary.',
                      style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.navyText),
                    ),
                    if (batch.replacedProductsCount > 0)
                      Text(
                        '• ${batch.replacedProductsCount} replaced products will be RESTORED to their exact previous version in Firestore and Algolia.',
                        style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.navyText),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isPhoto ? 'Rollback Photos' : 'Rollback & Delete',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRollingBack = true);
    try {
      await _excelService.rollbackBatch(batch.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully rolled back batch "${batch.fileName}" and deleted images from cloud.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, stack) {
      debugPrint('Rollback error: $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rollback failed: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRollingBack = false);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BUILD METHOD & SCAFFOLD
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Bulk Product Manager',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyText),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.royalBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.royalBlue,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12.5),
          tabs: const [
            Tab(icon: Icon(Icons.table_chart_outlined, size: 19), text: '1. Products Excel'),
            Tab(icon: Icon(Icons.photo_library_outlined, size: 19), text: '2. Photos (.zip)'),
            Tab(icon: Icon(Icons.history_rounded, size: 19), text: '3. History & Rollback'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExcelTab(),
          _buildZipTab(),
          _buildHistoryTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget? _buildBottomBar() {
    if (_tabController.index == 0) {
      // Excel Bottom Bar
      if (_importResult == null) return null;
      final replaceCount = _importResult!.duplicates
          .where((c) => _duplicateResolutions[c.importedProduct.id] == 'replace')
          .length;
      final keepBothCount = _importResult!.duplicates
          .where((c) => _duplicateResolutions[c.importedProduct.id] == 'keep_both')
          .length;
      final count = _importResult!.validProducts.length + replaceCount + keepBothCount;

      if (count == 0) return null;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
          boxShadow: const [
            BoxShadow(color: Color(0x0C000000), blurRadius: 14, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isUploading) ...[
                LinearProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uploading products... ${(_uploadProgress * 100).toInt()}%',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _handleCommitUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 22),
                  label: Text(
                    _isUploading ? 'Uploading to Cloud...' : 'Commit $count Products to Cloud',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_tabController.index == 1) {
      // ZIP Bottom Bar
      if (_zipResult == null || _zipResult!.matches.isEmpty) return null;
      final totalPhotos = _zipResult!.matches.fold(0, (sum, m) => sum + m.images.length);
      final totalProducts = _zipResult!.matches.length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
          boxShadow: const [
            BoxShadow(color: Color(0x0C000000), blurRadius: 14, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isUploadingZip) ...[
                LinearProgressIndicator(
                  value: _zipUploadProgress > 0 ? _zipUploadProgress : null,
                  backgroundColor: AppColors.royalBlue.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(AppColors.royalBlue),
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 8),
                Text(
                  _zipUploadStatusText,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.royalBlue),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isUploadingZip ? null : _handleCommitZipUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 22),
                  label: Text(
                    _isUploadingZip
                        ? 'Uploading Photos...'
                        : 'Upload $totalPhotos Photos & Link $totalProducts Products',
                    style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 1 WIDGET: EXCEL UPLOAD
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildExcelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExcelInstructionsCard(),
          const SizedBox(height: 20),

          // Step 1: Download Sample
          _buildStepCard(
            stepNumber: '1',
            title: 'Get Official Excel Template',
            description: 'Download the pre-formatted Excel template with all required columns, example stationery products, and instructions.',
            buttonLabel: 'Download / Share Template',
            buttonIcon: Icons.download_rounded,
            buttonColor: AppColors.royalBlue,
            onPressed: _handleDownloadTemplate,
          ),
          const SizedBox(height: 16),

          // Step 2: Upload File
          _buildStepCard(
            stepNumber: '2',
            title: 'Select Filled Excel / CSV File',
            description: 'Select your populated spreadsheet. The system will automatically detect categories, brands, and duplicate products.',
            buttonLabel: _isProcessingFile ? 'Reading & Validating...' : 'Choose Excel / CSV File',
            buttonIcon: Icons.file_upload_rounded,
            buttonColor: AppColors.primary,
            isLoading: _isProcessingFile,
            onPressed: _isProcessingFile || _isUploading ? null : _handlePickFile,
          ),
          const SizedBox(height: 24),

          // Parsed Results
          if (_importResult != null) ...[
            _buildExcelPreviewHeader(),
            const SizedBox(height: 14),

            if (_importResult!.autoCreatedCategories.isNotEmpty || _importResult!.autoCreatedBrands.isNotEmpty) ...[
              _buildAutoCreatedEntitiesCard(),
              const SizedBox(height: 16),
            ],

            if (_importResult!.hasDuplicates) ...[
              _buildDuplicatesResolutionCard(),
              const SizedBox(height: 16),
            ],

            if (_importResult!.hasErrors) ...[
              _buildWarningsBox(),
              const SizedBox(height: 16),
            ],

            if (_importResult!.hasValidProducts) ...[
              Text(
                'New Products to Add (${_importResult!.validProducts.length})',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navyText),
              ),
              const SizedBox(height: 10),
              _buildExcelProductsPreviewList(_importResult!.validProducts),
              const SizedBox(height: 24),
            ],
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 2 WIDGET: ZIP PHOTOS UPLOAD
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildZipTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildZipInstructionsCard(),
          const SizedBox(height: 20),

          // Step 1: Pick ZIP
          _buildStepCard(
            stepNumber: '1',
            title: 'Select Compressed Photos (.zip) Archive',
            description: 'Pick the ZIP file containing your photos grouped into product folders. The app will inspect all photos and match them automatically.',
            buttonLabel: _isProcessingZip ? 'Unpacking & Matching...' : 'Choose .zip Archive',
            buttonIcon: Icons.folder_zip_rounded,
            buttonColor: AppColors.royalBlue,
            isLoading: _isProcessingZip,
            onPressed: _isProcessingZip || _isUploadingZip ? null : _handlePickZip,
          ),
          const SizedBox(height: 24),

          // ZIP Match Preview
          if (_zipResult != null) ...[
            _buildZipMatchHeader(),
            const SizedBox(height: 16),

            // Mode Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 20, color: AppColors.royalBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Replace current photos with ZIP photos',
                      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.navyText),
                    ),
                  ),
                  Switch.adaptive(
                    value: _replaceExistingPhotos,
                    activeColor: AppColors.royalBlue,
                    onChanged: (val) => setState(() => _replaceExistingPhotos = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Matched Products List
            if (_zipResult!.matches.isNotEmpty) ...[
              Text(
                'Matched Products (${_zipResult!.matches.length})',
                style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.navyText),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _zipResult!.matches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final match = _zipResult!.matches[idx];
                  return _buildZipMatchCard(match);
                },
              ),
              const SizedBox(height: 24),
            ],

            // Unmatched Folders
            if (_zipResult!.unmatched.isNotEmpty) ...[
              Text(
                'Unmatched Folders (${_zipResult!.unmatched.length})',
                style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.warning),
              ),
              const SizedBox(height: 6),
              Text(
                'These folder names did not find an exact match in Firestore. You can rename them to match the product name or assign them manually.',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _zipResult!.unmatched.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final unmatchedItem = _zipResult!.unmatched[idx];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_off_rounded, color: Color(0xFFD97706), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unmatchedItem.folderName,
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyText),
                              ),
                              Text(
                                '${unmatchedItem.images.length} photos found inside',
                                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildZipMatchHeader() {
    final matchCount = _zipResult!.matches.length;
    final totalPhotos = _zipResult!.matches.fold(0, (sum, m) => sum + m.images.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$matchCount Products Matched Successfully',
                  style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalPhotos photos extracted and ready to upload to Cloudinary.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.navyText.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZipMatchCard(ZipProductMatch match) {
    final product = match.matchedProduct!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.navyText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Folder: "${match.folderName}" • ${AppFormatters.formatPrice(product.price)}',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${match.images.length} Photos',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.royalBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Preview of Extracted Photos
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: match.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final img = match.images[i];
                final isCover = i == 0;

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        img.bytes,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCover ? AppColors.primary : Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCover ? 'Cover' : '#${i + 1}',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZipInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.royalBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ZIP Bulk Photo Upload Guide',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.royalBlue),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Have your photographer organize photos in folders matching Product Names (e.g. "Category/Product Name/1.jpg, 2.jpg...").\n'
                  '• Number photos 1.jpg, 2.jpg, 3.jpg, 4.jpg. 1.jpg becomes the main cover photo.\n'
                  '• Zip the main folder and upload it here. The app automatically links all photos to your products.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.navyText.withValues(alpha: 0.8), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 3 WIDGET: HISTORY & ROLLBACK
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    return StreamBuilder<List<BulkImportBatchModel>>(
      stream: _excelService.watchBatchHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading history: ${snapshot.error}', style: GoogleFonts.poppins(color: AppColors.error)),
          );
        }

        final batches = snapshot.data ?? [];
        if (batches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('No Bulk Imports Yet',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyText)),
                const SizedBox(height: 6),
                Text('Past Excel import batches will appear here with one-click rollback.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: batches.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final batch = batches[index];
            final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(batch.timestamp);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: batch.isRolledBack ? AppColors.border : AppColors.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            batch.isPhotoBatch ? Icons.photo_library_rounded : Icons.table_chart_rounded,
                            size: 18,
                            color: batch.isPhotoBatch ? AppColors.royalBlue : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            batch.isPhotoBatch ? 'ZIP Photos Upload' : 'Excel Products Import',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: batch.isPhotoBatch ? AppColors.royalBlue : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: batch.isRolledBack
                              ? AppColors.textHint.withValues(alpha: 0.15)
                              : AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          batch.isRolledBack ? 'Rolled Back' : 'Active',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: batch.isRolledBack ? AppColors.textSecondary : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    batch.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.navyText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      if (batch.isPhotoBatch) ...[
                        _buildBatchStat('Products Linked', '${batch.totalCount}'),
                        _buildBatchStat('Photos in Cloud', '${batch.uploadedPhotosCount}'),
                      ] else ...[
                        _buildBatchStat('Total Products', '${batch.totalCount}'),
                        _buildBatchStat('New', '${batch.newProductsCount}'),
                        _buildBatchStat('Replaced', '${batch.replacedProductsCount}'),
                        if (batch.createdCategoryIds.isNotEmpty)
                          _buildBatchStat('Categories', '${batch.createdCategoryIds.length}'),
                        if (batch.createdBrandIds.isNotEmpty)
                          _buildBatchStat('Brands', '${batch.createdBrandIds.length}'),
                      ],
                    ],
                  ),
                  if (!batch.isRolledBack) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isRollingBack ? null : () => _handleRollback(batch),
                        icon: _isRollingBack
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                              )
                            : const Icon(Icons.undo_rounded, size: 18),
                        label: Text(
                          _isRollingBack
                              ? 'Rolling back...'
                              : (batch.isPhotoBatch
                                  ? 'Rollback Photos (Delete from Cloudinary)'
                                  : 'Rollback Products (Delete From Cloud)'),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ] else if (batch.rolledBackAt != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Reverted on ${DateFormat('dd MMM yyyy, hh:mm a').format(batch.rolledBackAt!)}',
                      style: GoogleFonts.poppins(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textHint),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // COMMON HELPER WIDGETS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildBatchStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textHint)),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyText)),
        ],
      ),
    );
  }

  Widget _buildExcelInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline_rounded, color: AppColors.royalBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulk Product Upload Guide',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.royalBlue),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Fill out the sample Excel template with your stationery products.\n'
                  '• Missing categories and brands are automatically detected and created on the fly.\n'
                  '• Duplicate products will be flagged so you can choose to replace or skip them.\n'
                  '• Full history is recorded so you can roll back the import and delete items from cloud anytime.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.navyText.withValues(alpha: 0.8), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    required String buttonLabel,
    required IconData buttonIcon,
    required Color buttonColor,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: buttonColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  stepNumber,
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navyText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(buttonIcon, size: 20),
              label: Text(
                buttonLabel,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcelPreviewHeader() {
    final validCount = _importResult!.validProducts.length;
    final dupCount = _importResult!.duplicates.length;

    return Row(
      children: [
        Text(
          'Products Preview',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyText),
        ),
        const Spacer(),
        if (dupCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$dupCount Conflicts',
              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFFD97706)),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$validCount New Products',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoCreatedEntitiesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 8),
              Text(
                'Auto-Creating Missing Categories & Brands',
                style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The following categories and brands were found in your spreadsheet but do not exist in the database yet. They will be automatically created with all required fields:',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.navyText.withValues(alpha: 0.8), height: 1.35),
          ),
          const SizedBox(height: 10),
          if (_importResult!.autoCreatedCategories.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _importResult!.autoCreatedCategories.map((c) {
                return Chip(
                  backgroundColor: Colors.white,
                  avatar: const Icon(Icons.category_outlined, size: 16, color: Color(0xFF16A34A)),
                  label: Text('Category: ${c.name}',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A))),
                  side: const BorderSide(color: Color(0xFFBBF7D0)),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
          ],
          if (_importResult!.autoCreatedBrands.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _importResult!.autoCreatedBrands.map((b) {
                return Chip(
                  backgroundColor: Colors.white,
                  avatar: const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF0284C7)),
                  label: Text('Brand: ${b.name}',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0284C7))),
                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDuplicatesResolutionCard() {
    final duplicates = _importResult!.duplicates;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Duplicate Products Reminder (${duplicates.length} already exist)',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFD97706)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'The products below share exact names with existing products in your store. Choose whether to replace them with the new details from Excel, skip them, or keep both as separate items:',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.navyText.withValues(alpha: 0.8), height: 1.35),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyResolutionToAll('replace'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFD97706)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text('Replace All', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFFD97706))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyResolutionToAll('skip'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text('Skip All', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyResolutionToAll('keep_both'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text('Keep Both', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: duplicates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final conf = duplicates[idx];
              final currentChoice = _duplicateResolutions[conf.importedProduct.id] ?? 'replace';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conf.importedProduct.name,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyText),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Existing: ${AppFormatters.formatPrice(conf.existingProduct.price)} (Stock: ${conf.existingProduct.stock})',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textHint),
                        const SizedBox(width: 8),
                        Text(
                          'New: ${AppFormatters.formatPrice(conf.importedProduct.price)} (Stock: ${conf.importedProduct.stock})',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildChoiceChip(
                          label: 'Replace',
                          selected: currentChoice == 'replace',
                          color: const Color(0xFFD97706),
                          onTap: () => setState(() => _duplicateResolutions[conf.importedProduct.id] = 'replace'),
                        ),
                        const SizedBox(width: 6),
                        _buildChoiceChip(
                          label: 'Skip',
                          selected: currentChoice == 'skip',
                          color: AppColors.textSecondary,
                          onTap: () => setState(() => _duplicateResolutions[conf.importedProduct.id] = 'skip'),
                        ),
                        const SizedBox(width: 6),
                        _buildChoiceChip(
                          label: 'Keep Both',
                          selected: currentChoice == 'keep_both',
                          color: AppColors.primary,
                          onTap: () => setState(() => _duplicateResolutions[conf.importedProduct.id] = 'keep_both'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildWarningsBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_importResult!.errors.length} Warning(s) in File',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._importResult!.errors.take(5).map(
                (err) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $err',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.navyText),
                  ),
                ),
              ),
          if (_importResult!.errors.length > 5)
            Text(
              'and ${_importResult!.errors.length - 5} more issues...',
              style: GoogleFonts.poppins(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildExcelProductsPreviewList(List<ProductModel> products) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = products[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navyText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Brand: ${p.brand}  •  Stock: ${p.stock} ${p.unit}',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          AppFormatters.formatPrice(p.price),
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.royalBlue),
                        ),
                        if (p.mrp > p.price) ...[
                          const SizedBox(width: 6),
                          Text(
                            AppFormatters.formatPrice(p.mrp),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textHint,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWarm,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Photo Pending',
                            style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
