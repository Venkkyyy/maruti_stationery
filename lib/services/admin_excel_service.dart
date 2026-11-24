import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/brand_model.dart';
import '../models/bulk_import_batch_model.dart';
import 'admin_zip_image_service.dart';
import 'algolia_admin_service.dart' as maruti_algolia;

/// Service for exporting orders to Excel (.xlsx / .csv) and bulk importing products from Excel.
class AdminExcelService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────────────────────────────────────────────────────────────────────────
  // 1. ORDER EXPORT TO EXCEL (.xlsx) & CSV
  // ───────────────────────────────────────────────────────────────────────────

  /// Exports [orders] to an Excel workbook with comprehensive details and summary tabs.
  Future<String> exportOrdersToExcel(
    List<OrderModel> orders, {
    String filterLabel = 'All Orders',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Orders');

    final sheet = excel['Orders'];

    // Header styling
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#173A9B'), // Royal Blue
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final List<String> headers = [
      'Order ID',
      'Date & Time',
      'Customer Name',
      'Phone Number',
      'Status',
      'Delivery Category',
      'Items Summary',
      'Total Items',
      'Subtotal (₹)',
      'Delivery (₹)',
      'Discount (₹)',
      'Loyalty Points',
      'Grand Total (₹)',
      'Payment Method',
      'Payment Status',
      'Delivery Address',
      'Delivery Code',
    ];

    // Append Header Row
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    // Append Order Data Rows
    for (int i = 0; i < orders.length; i++) {
      final o = orders[i];
      final rowIndex = i + 1;

      final isDelivered = o.status == OrderStatus.delivered;
      final deliveryCategory = isDelivered ? 'Delivered' : (o.status == OrderStatus.cancelled ? 'Cancelled' : 'Not Delivered / In-Progress');

      final itemsSummary = o.items.map((it) => '${it.qty}x ${it.name} (₹${(it.price / 100).toStringAsFixed(2)})').join('; ');
      final totalQty = o.items.fold<int>(0, (sum, it) => sum + it.qty);

      final addressStr = '${o.address.name}, ${o.address.street}, ${o.address.city}, ${o.address.state} - ${o.address.pincode}';

      final rowValues = [
        o.id,
        dateFormat.format(o.createdAt),
        o.address.name,
        o.address.phone,
        o.status.name.toUpperCase(),
        deliveryCategory,
        itemsSummary,
        totalQty.toString(),
        (o.subtotal / 100).toStringAsFixed(2),
        (o.deliveryCharge / 100).toStringAsFixed(2),
        (o.discount / 100).toStringAsFixed(2),
        o.pointsUsed.toString(),
        (o.total / 100).toStringAsFixed(2),
        o.paymentMethod.name.toUpperCase(),
        o.paymentStatus.name.toUpperCase(),
        addressStr,
        o.deliveryCode ?? 'N/A',
      ];

      for (int col = 0; col < rowValues.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
        cell.value = TextCellValue(rowValues[col]);
      }
    }

    // ── Create Second Sheet: "Summary by Status" ─────────────────────────────
    final summarySheet = excel['Summary by Status'];
    final summaryHeaders = ['Status Category', 'Order Count', 'Total Items Sold', 'Total Revenue (₹)'];

    for (int col = 0; col < summaryHeaders.length; col++) {
      final cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(summaryHeaders[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#FF681F'), // Orange Accent
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Calculate aggregations
    final Map<String, _StatusStats> stats = {};
    for (final o in orders) {
      final key = o.status.name.toUpperCase();
      stats.putIfAbsent(key, () => _StatusStats());
      stats[key]!.count++;
      stats[key]!.totalItems += o.items.fold<int>(0, (sum, it) => sum + it.qty);
      stats[key]!.totalPaise += o.total;
    }

    int sumRow = 1;
    stats.forEach((statusKey, stat) {
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sumRow)).value = TextCellValue(statusKey);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: sumRow)).value = IntCellValue(stat.count);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: sumRow)).value = IntCellValue(stat.totalItems);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: sumRow)).value = DoubleCellValue(stat.totalPaise / 100);
      sumRow++;
    });

    // Save File
    final fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Failed to generate Excel file bytes');
    }

    final tempDir = await getTemporaryDirectory();
    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final sanitizedFilter = filterLabel.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final filePath = '${tempDir.path}/Maruti_Orders_${sanitizedFilter}_$nowStr.xlsx';

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    // Share File via native system UI
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Maruti Stationery Orders Report ($filterLabel)',
      text: 'Exported ${orders.length} orders ($filterLabel) from Maruti Stationery Admin.',
    );

    return filePath;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. SAMPLE PRODUCT IMPORT EXCEL TEMPLATE GENERATION
  // ───────────────────────────────────────────────────────────────────────────

  /// Generates and shares a sample Excel template with pre-filled examples so the
  /// admin knows the exact format for bulk product upload.
  Future<String> downloadSampleProductTemplate() async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Products');

    final sheet = excel['Products'];

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#173A9B'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final List<String> headers = [
      'Product Name*',
      'Category Name*',
      'SubCategory',
      'Brand*',
      'Selling Price (₹)*',
      'MRP (₹)*',
      'Stock Quantity*',
      'Unit*',
      'Description',
      'Search Tags (comma-separated)',
      'Is Returnable (YES/NO)',
      'Return Policy',
      'Highlights (semicolon-separated)',
      'Specifications (Key:Value separated by ;)',
    ];

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // Realistic sample rows
    final sampleRows = [
      [
        'Classmate Pulse Spiral Notebook A4 (300 Pages)',
        'Notebooks',
        'Spiral Notebooks',
        'Classmate',
        '180',
        '220',
        '50',
        'piece',
        'High quality single line spiral notebook with 70 GSM elemental chlorine-free paper.',
        'notebook, spiral, a4, study, classmate, writing',
        'YES',
        '7 days returnable if unused',
        '300 pages; Single line ruled; 70 GSM bright paper; Sturdy spiral binding',
        'Pages:300; Size:A4; Ruling:Single Line; Brand:Classmate',
      ],
      [
        'Reynolds 045 Fine Carbide Ball Pen (Pack of 10)',
        'Pens & Writing',
        'Ball Pens',
        'Reynolds',
        '100',
        '120',
        '100',
        'pack',
        'Classic smooth writing ball pens with laser tip for precision and smudge-free handwriting.',
        'pen, ball pen, blue ink, reynolds, pack, school stationery',
        'NO',
        'Non-returnable',
        '0.7mm fine tip; Smudge resistant ink; Long writing length; Comfortable grip',
        'Tip Size:0.7mm; Ink Color:Blue; Pack Count:10; Type:Ballpoint',
      ],
      [
        'Doms Non-Toxic 24 Shade Oil Pastels',
        'Art & Craft',
        'Colors',
        'Doms',
        '140',
        '160',
        '40',
        'set',
        'Vibrant color oil pastels designed for smooth laydown and effortless blending.',
        'crayons, oil pastels, doms, colors, drawing, art and craft',
        'YES',
        '7 days replacement on damaged arrival',
        '24 rich shades; Super smooth blending; Non-toxic and child safe; Includes scraping tool',
        'Shades:24; Form:Stick; Safety:Non-Toxic; Brand:Doms',
      ],
    ];

    for (int r = 0; r < sampleRows.length; r++) {
      final rowData = sampleRows[r];
      for (int c = 0; c < rowData.length; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1)).value = TextCellValue(rowData[c]);
      }
    }

    // Sheet 2: Help & Guidelines
    final guideSheet = excel['Instructions & Notes'];
    final notes = [
      'IMPORTANT BULK PRODUCT IMPORT INSTRUCTIONS:',
      '1. Columns marked with * are required: Name, Category, Brand, Price, MRP, Stock, Unit.',
      '2. Prices must be entered in Indian Rupees (₹). The app automatically converts them.',
      '3. Stock must be an integer (e.g. 10, 50, 100).',
      '4. IMAGES NOTICE: Product photos cannot be uploaded directly via Excel.',
      '   All bulk-imported products are automatically added to your cloud catalog.',
      '   You can attach photos anytime individually from the Admin App by clicking "Edit Product" or using the "Missing Photos" filter.',
      '5. Categories will be automatically linked to your existing categories in Maruti Stationery.',
    ];

    for (int i = 0; i < notes.length; i++) {
      guideSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).value = TextCellValue(notes[i]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Failed to generate sample Excel file');
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/Maruti_Bulk_Product_Template.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Maruti Bulk Product Template',
      text: 'Sample Excel template for bulk product import into Maruti Stationery.',
    );

    return filePath;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. PARSE PRODUCTS FROM EXCEL (.xlsx) OR CSV (.csv)
  // ───────────────────────────────────────────────────────────────────────────

  static const String _cloudinaryCloudName = 'eizhyg2w';

  /// Helper to convert text to URL/ID friendly slug
  String _slugify(String input) {
    final s = input.trim().toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return s.isEmpty ? 'general' : s;
  }

  /// Parses file bytes into [BulkImportResult], automatically detecting duplicates,
  /// planning category auto-creation, and brand auto-creation with all required fields.
  Future<BulkImportResult> parseProductFile({
    required Uint8List fileBytes,
    required String fileName,
    required List<CategoryModel> availableCategories,
    List<BrandModel> availableBrands = const [],
  }) async {
    final lowerName = fileName.toLowerCase();
    List<List<dynamic>> rows = [];

    if (lowerName.endsWith('.csv')) {
      final csvString = String.fromCharCodes(fileBytes);
      rows = Csv(dynamicTyping: false).decode(csvString);
    } else {
      final wb = Excel.decodeBytes(fileBytes);
      String? targetSheet;

      // 1. Look for a sheet named 'Products' (case-insensitive)
      for (final key in wb.tables.keys) {
        if (key.trim().toLowerCase() == 'products') {
          targetSheet = key;
          break;
        }
      }

      // 2. If not found, look for a sheet whose first row contains product headers
      if (targetSheet == null) {
        for (final key in wb.tables.keys) {
          final sheet = wb.tables[key];
          if (sheet != null && sheet.rows.isNotEmpty) {
            final firstRowText = sheet.rows.first.map((c) => c?.value?.toString().toLowerCase() ?? '').join(' ');
            if (firstRowText.contains('product') || (firstRowText.contains('name') && firstRowText.contains('price'))) {
              targetSheet = key;
              break;
            }
          }
        }
      }

      // 3. Fallback to first sheet
      targetSheet ??= wb.tables.keys.firstOrNull;

      if (targetSheet != null) {
        for (final row in wb[targetSheet].rows) {
          final rowValues = row.map((c) => c?.value?.toString().trim() ?? '').toList();
          rows.add(rowValues);
        }
      }
    }

    if (rows.isEmpty || rows.length < 2) {
      return BulkImportResult(
        validProducts: [],
        duplicates: [],
        autoCreatedCategories: [],
        autoCreatedBrands: [],
        errors: ['The selected file is empty or does not contain a valid data row.'],
      );
    }

    // Detect header row (row 0 or row 1)
    int headerRowIndex = 0;
    for (int r = 0; r < rows.length && r < 5; r++) {
      final rowText = rows[r].map((c) => c.toString().toLowerCase()).join(' ');
      if (rowText.contains('product') || (rowText.contains('name') && (rowText.contains('price') || rowText.contains('category')))) {
        headerRowIndex = r;
        break;
      }
    }

    // Match header columns flexibly
    final headerRow = rows[headerRowIndex].map((h) => h.toString().toLowerCase().trim()).toList();

    int findCol(List<String> matchers) {
      for (int i = 0; i < headerRow.length; i++) {
        for (final m in matchers) {
          if (headerRow[i].contains(m.toLowerCase())) return i;
        }
      }
      return -1;
    }

    final colName = findCol(['product name', 'name', 'title']);
    final colCat = findCol(['category name', 'category']);
    final colSubCat = findCol(['subcategory', 'sub category']);
    final colBrand = findCol(['brand']);
    final colPrice = findCol(['selling price', 'price', 'rate']);
    final colMrp = findCol(['mrp', 'original price']);
    final colStock = findCol(['stock', 'quantity', 'qty']);
    final colUnit = findCol(['unit', 'uom']);
    final colDesc = findCol(['description', 'desc']);
    final colTags = findCol(['tags', 'search tags', 'keywords']);
    final colReturn = findCol(['returnable', 'is returnable']);
    final colReturnPol = findCol(['return policy', 'policy']);
    final colHighlights = findCol(['highlights', 'features']);
    final colSpecs = findCol(['specifications', 'specs']);

    // Fetch existing categories, brands, and products from Firestore for duplicate detection
    final categoriesSnap = await _db.collection('categories').get();
    final allCategories = categoriesSnap.docs.map((d) => CategoryModel.fromFirestore(d)).toList();

    final brandsSnap = await _db.collection('brands').get();
    final allBrands = brandsSnap.docs.map((d) => BrandModel.fromFirestore(d)).toList();

    final productsSnap = await _db.collection('products').get();
    final Map<String, ProductModel> existingProductsByName = {};
    for (final doc in productsSnap.docs) {
      final p = ProductModel.fromFirestore(doc);
      existingProductsByName[p.name.trim().toLowerCase()] = p;
    }

    final Map<String, CategoryModel> newlyCreatedCategories = {};
    final Map<String, BrandModel> newlyCreatedBrands = {};
    final List<ProductModel> validProducts = [];
    final List<ProductConflict> duplicates = [];
    final List<String> errors = [];

    // Track names in this import file to detect duplicate rows in the same sheet
    final Set<String> fileSeenProductNames = {};

    for (int r = headerRowIndex + 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.every((cell) => cell.toString().trim().isEmpty)) continue;

      String getVal(int colIdx) {
        if (colIdx >= 0 && colIdx < row.length) {
          return row[colIdx].toString().trim();
        }
        return '';
      }

      final name = colName >= 0 ? getVal(colName) : (row.isNotEmpty ? row[0].toString().trim() : '');
      if (name.isEmpty) {
        errors.add('Row ${r + 1}: Product name is missing.');
        continue;
      }

      final catName = colCat >= 0 ? getVal(colCat) : '';
      final brandName = colBrand >= 0 ? getVal(colBrand) : 'Maruti';
      final priceStr = colPrice >= 0 ? getVal(colPrice) : '';
      final mrpStr = colMrp >= 0 ? getVal(colMrp) : '';
      final stockStr = colStock >= 0 ? getVal(colStock) : '10';
      final unit = (colUnit >= 0 ? getVal(colUnit) : 'piece').toLowerCase();
      final desc = colDesc >= 0 ? getVal(colDesc) : '';
      final tagsStr = colTags >= 0 ? getVal(colTags) : '';
      final returnStr = colReturn >= 0 ? getVal(colReturn).toUpperCase() : 'NO';
      final returnPol = colReturnPol >= 0 ? getVal(colReturnPol) : null;
      final highlightsStr = colHighlights >= 0 ? getVal(colHighlights) : '';
      final specsStr = colSpecs >= 0 ? getVal(colSpecs) : '';

      final double? priceRupees = double.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (priceRupees == null || priceRupees <= 0) {
        errors.add('Row ${r + 1} ("$name"): Invalid selling price "$priceStr".');
        continue;
      }

      final double mrpRupees = double.tryParse(mrpStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? priceRupees;
      final int stock = int.tryParse(stockStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      // ── Intelligent Category Resolution & Auto-Creation ──
      String resolvedCategoryId = 'general';
      if (catName.isNotEmpty) {
        // Search in existing categories
        final matchedCat = allCategories.where((c) =>
          c.name.trim().toLowerCase() == catName.toLowerCase() ||
          c.id.toLowerCase() == catName.toLowerCase()
        ).firstOrNull;

        if (matchedCat != null) {
          resolvedCategoryId = matchedCat.id;
        } else if (newlyCreatedCategories.containsKey(catName.toLowerCase())) {
          resolvedCategoryId = newlyCreatedCategories[catName.toLowerCase()]!.id;
        } else {
          // Auto-create category with clean slug and required fields
          final slug = _slugify(catName);
          final autoCat = CategoryModel(
            id: slug,
            name: catName,
            image: '',
            imageDeleteToken: null,
            parentId: null,
            order: allCategories.length + newlyCreatedCategories.length + 1,
            isActive: true,
          );
          newlyCreatedCategories[catName.toLowerCase()] = autoCat;
          resolvedCategoryId = autoCat.id;
        }
      }

      // ── Intelligent Brand Resolution & Auto-Creation ──
      String resolvedBrandId = 'maruti';
      String resolvedBrandName = brandName.isNotEmpty ? brandName : 'Maruti';
      if (brandName.isNotEmpty) {
        final matchedBrand = allBrands.where((b) =>
          b.name.trim().toLowerCase() == brandName.toLowerCase() ||
          b.id.toLowerCase() == brandName.toLowerCase()
        ).firstOrNull;

        if (matchedBrand != null) {
          resolvedBrandId = matchedBrand.id;
          resolvedBrandName = matchedBrand.name;
        } else if (newlyCreatedBrands.containsKey(brandName.toLowerCase())) {
          final b = newlyCreatedBrands[brandName.toLowerCase()]!;
          resolvedBrandId = b.id;
          resolvedBrandName = b.name;
        } else {
          final slug = _slugify(brandName);
          final autoBrand = BrandModel(
            id: slug,
            name: brandName,
            logoUrl: '',
            isActive: true,
            createdAt: DateTime.now(),
          );
          newlyCreatedBrands[brandName.toLowerCase()] = autoBrand;
          resolvedBrandId = autoBrand.id;
          resolvedBrandName = autoBrand.name;
        }
      }

      // Tags building
      final List<String> tags = [
        ...name.toLowerCase().split(RegExp(r'[\s,]+')),
        resolvedBrandName.toLowerCase(),
        catName.toLowerCase(),
      ];
      if (tagsStr.isNotEmpty) {
        tags.addAll(tagsStr.split(',').map((t) => t.trim().toLowerCase()));
      }
      final cleanedTags = tags.where((t) => t.length > 1).toSet().toList();

      // Highlights
      final List<String> highlights = highlightsStr.isNotEmpty
          ? highlightsStr.split(';').map((h) => h.trim()).where((h) => h.isNotEmpty).toList()
          : [];

      // Specifications Map
      final Map<String, String> specifications = {};
      if (specsStr.isNotEmpty) {
        final pairs = specsStr.split(';');
        for (final pair in pairs) {
          final parts = pair.split(':');
          if (parts.length >= 2) {
            specifications[parts[0].trim()] = parts.sublist(1).join(':').trim();
          }
        }
      }

      final product = ProductModel(
        id: const Uuid().v4(),
        name: name,
        description: desc.isNotEmpty ? desc : 'High quality stationery item from Maruti Stationery.',
        price: (priceRupees * 100).toInt(),
        mrp: (mrpRupees * 100).toInt(),
        categoryId: resolvedCategoryId,
        subCategoryId: colSubCat >= 0 && getVal(colSubCat).isNotEmpty ? getVal(colSubCat) : null,
        brand: resolvedBrandName,
        brandId: resolvedBrandId,
        stock: stock,
        unit: unit.isNotEmpty ? unit : 'piece',
        tags: cleanedTags,
        isActive: true,
        isReturnable: returnStr == 'YES' || returnStr == 'TRUE' || returnStr == '1',
        returnPolicy: returnPol,
        images: const [],
        imageDeleteTokens: const [],
        highlights: highlights,
        specifications: specifications,
        createdAt: DateTime.now(),
      );

      final lowerTitle = name.trim().toLowerCase();
      // Check if product already exists in Firestore or duplicate in sheet
      if (existingProductsByName.containsKey(lowerTitle)) {
        duplicates.add(ProductConflict(
          existingProduct: existingProductsByName[lowerTitle]!,
          importedProduct: product,
        ));
      } else if (fileSeenProductNames.contains(lowerTitle)) {
        // Internal conflict within same sheet
        errors.add('Row ${r + 1}: Duplicate product name "$name" found multiple times in this spreadsheet.');
      } else {
        fileSeenProductNames.add(lowerTitle);
        validProducts.add(product);
      }
    }

    return BulkImportResult(
      validProducts: validProducts,
      duplicates: duplicates,
      autoCreatedCategories: newlyCreatedCategories.values.toList(),
      autoCreatedBrands: newlyCreatedBrands.values.toList(),
      errors: errors,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. COMMIT BULK IMPORT WITH DUPLICATE RESOLUTION & BATCH HISTORY
  // ───────────────────────────────────────────────────────────────────────────

  /// Executes bulk import:
  /// - Auto-creates any new categories & brands
  /// - Creates new products
  /// - Applies admin choices to duplicates ('replace', 'skip', or 'keep_both')
  /// - Stores rollback batch in Firestore `/bulk_import_batches`
  /// - Syncs to Algolia
  Future<BulkImportBatchModel> commitBulkImport({
    required String fileName,
    required String? adminEmail,
    required List<ProductModel> productsToCreate,
    required List<CategoryModel> categoriesToCreate,
    required List<BrandModel> brandsToCreate,
    required Map<String, String> duplicateResolutions, // importedProductId -> 'replace' | 'skip' | 'keep_both'
    required List<ProductConflict> duplicateConflicts,
    void Function(int completed, int total)? onProgress,
  }) async {
    final batchId = const Uuid().v4();
    final List<String> createdProductIds = [];
    final Map<String, dynamic> updatedProductSnapshots = {};

    // 1. Auto-create Categories in Firestore
    for (final cat in categoriesToCreate) {
      try {
        await _db.collection('categories').doc(cat.id).set(cat.toFirestore());
      } catch (e) {
        debugPrint('Warning: Category creation failed for ${cat.name}: $e');
      }
    }

    // 2. Auto-create Brands in Firestore
    for (final brand in brandsToCreate) {
      try {
        await _db.collection('brands').doc(brand.id).set(brand.toMap());
      } catch (e) {
        debugPrint('Warning: Brand creation failed for ${brand.name}: $e');
      }
    }

    // 3. Process Duplicate Conflicts according to admin choices
    final List<ProductModel> finalProductsToCreate = List.from(productsToCreate);

    for (final conflict in duplicateConflicts) {
      final choice = duplicateResolutions[conflict.importedProduct.id] ?? 'replace';

      if (choice == 'skip') {
        continue;
      } else if (choice == 'keep_both') {
        // Keep both: create a new product with distinct ID
        finalProductsToCreate.add(conflict.importedProduct);
      } else {
        // 'replace': Overwrite existing product in Firestore, retaining its ID and photos if imported has none
        final existing = conflict.existingProduct;
        final imported = conflict.importedProduct;

        // Save previous snapshot for rollback (ensure updatedAt is concrete Timestamp rather than FieldValue)
        final snapshot = existing.toFirestore();
        snapshot['updatedAt'] = Timestamp.now();
        updatedProductSnapshots[existing.id] = snapshot;

        final updated = imported.copyWith(
          id: existing.id,
          images: imported.images.isNotEmpty ? imported.images : existing.images,
          imageDeleteTokens: imported.imageDeleteTokens.isNotEmpty ? imported.imageDeleteTokens : existing.imageDeleteTokens,
          reviewCount: existing.reviewCount,
          averageRating: existing.averageRating,
        );

        await _db.collection('products').doc(existing.id).set(updated.toFirestore());
        // Sync update to Algolia
        try {
          await maruti_algolia.AlgoliaAdminService().syncProduct(updated);
        } catch (_) {}
      }
    }

    // 4. Batch Create New Products in Firestore
    const batchSize = 250;
    int completedCount = 0;
    final totalNew = finalProductsToCreate.length;

    for (int i = 0; i < finalProductsToCreate.length; i += batchSize) {
      final chunk = finalProductsToCreate.sublist(
        i,
        i + batchSize > finalProductsToCreate.length ? finalProductsToCreate.length : i + batchSize,
      );

      final writeBatch = _db.batch();

      for (final p in chunk) {
        final docRef = _db.collection('products').doc(p.id);
        writeBatch.set(docRef, p.toFirestore());
        createdProductIds.add(p.id);
      }

      await writeBatch.commit();
      completedCount += chunk.length;

      // Sync new products to Algolia
      for (final p in chunk) {
        try {
          await maruti_algolia.AlgoliaAdminService().syncProduct(p);
        } catch (_) {}
      }

      if (onProgress != null) {
        onProgress(completedCount, totalNew);
      }
    }

    // 5. Save Batch Record in Firestore for Rollback History
    final batchRecord = BulkImportBatchModel(
      id: batchId,
      fileName: fileName,
      timestamp: DateTime.now(),
      adminEmail: adminEmail,
      totalCount: createdProductIds.length + updatedProductSnapshots.length,
      newProductsCount: createdProductIds.length,
      replacedProductsCount: updatedProductSnapshots.length,
      createdProductIds: createdProductIds,
      updatedProductSnapshots: updatedProductSnapshots,
      createdCategoryIds: categoriesToCreate.map((c) => c.id).toList(),
      createdBrandIds: brandsToCreate.map((b) => b.id).toList(),
      isRolledBack: false,
    );

    await _db.collection('bulk_import_batches').doc(batchId).set(batchRecord.toMap());

    return batchRecord;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. ROLLBACK BATCH (DELETES FROM CLOUD & RESTORES PREVIOUS STATE)
  // ───────────────────────────────────────────────────────────────────────────

  /// Rolls back a bulk import batch:
  /// - Deletes newly created products from Cloudinary (using delete tokens), Algolia, and Firestore
  /// - Restores previously replaced products to their exact snapshot in Firestore and Algolia
  /// - Deletes auto-created categories & brands if they have no remaining products
  /// - Marks batch as rolled back
  Future<void> rollbackBatch(String batchId) async {
    final doc = await _db.collection('bulk_import_batches').doc(batchId).get();
    if (!doc.exists) {
      throw Exception('Import batch record not found ($batchId)');
    }

    final batch = BulkImportBatchModel.fromFirestore(doc);
    if (batch.isRolledBack) {
      throw Exception('This import batch has already been rolled back on ${batch.rolledBackAt}');
    }

    if (batch.isPhotoBatch) {
      await AdminZipImageService().rollbackZipBatch(batchId);
      return;
    }

    // 1. Delete created products from Cloudinary, Algolia, and Firestore
    for (final pid in batch.createdProductIds) {
      if (pid.trim().isEmpty) continue;

      // A. Extract image delete tokens and delete images from Cloudinary
      try {
        final pDoc = await _db.collection('products').doc(pid).get();
        if (pDoc.exists) {
          final data = pDoc.data();
          if (data != null && data['imageDeleteTokens'] is List) {
            for (final token in List.from(data['imageDeleteTokens'])) {
              if (token != null && token.toString().isNotEmpty) {
                try {
                  await _deleteCloudinaryImageByToken(token.toString());
                } catch (e) {
                  debugPrint('Cloudinary token delete failed for product $pid: $e');
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Warning reading product doc ($pid) for Cloudinary delete: $e');
      }

      // B. Delete from Algolia search index
      try {
        await maruti_algolia.AlgoliaAdminService().deleteProduct(pid);
      } catch (e) {
        debugPrint('Warning deleting from Algolia ($pid): $e');
      }

      // C. Delete product document from Firestore
      try {
        await _db.collection('products').doc(pid).delete();
      } catch (e) {
        debugPrint('Warning during Firestore product delete ($pid): $e');
      }
    }

    // Also delete any global delete tokens recorded on the batch
    for (final token in batch.uploadedDeleteTokens) {
      if (token.isNotEmpty) {
        try {
          await _deleteCloudinaryImageByToken(token);
        } catch (_) {}
      }
    }

    // 2. Restore replaced products to their previous version
    for (final entry in batch.updatedProductSnapshots.entries) {
      try {
        final pid = entry.key;
        if (entry.value is! Map) continue;
        final oldData = Map<String, dynamic>.from(entry.value as Map);
        await _db.collection('products').doc(pid).set(oldData);

        // Resync restored product to Algolia
        final restoredDoc = await _db.collection('products').doc(pid).get();
        if (restoredDoc.exists) {
          final restoredProduct = ProductModel.fromFirestore(restoredDoc);
          await maruti_algolia.AlgoliaAdminService().syncProduct(restoredProduct);
        }
      } catch (e) {
        debugPrint('Warning during product restore (${entry.key}): $e');
      }
    }

    // 3. Remove auto-created categories if no remaining products reference them
    for (final catId in batch.createdCategoryIds) {
      try {
        final prodsInCat = await _db.collection('products').where('categoryId', isEqualTo: catId).limit(1).get();
        if (prodsInCat.docs.isEmpty) {
          await _db.collection('categories').doc(catId).delete();
        }
      } catch (e) {
        debugPrint('Warning removing category ($catId): $e');
      }
    }

    // 4. Remove auto-created brands if no remaining products reference them
    for (final brandId in batch.createdBrandIds) {
      try {
        final prodsInBrand = await _db.collection('products').where('brandId', isEqualTo: brandId).limit(1).get();
        if (prodsInBrand.docs.isEmpty) {
          await _db.collection('brands').doc(brandId).delete();
        }
      } catch (e) {
        debugPrint('Warning removing brand ($brandId): $e');
      }
    }

    // 5. Update batch record in Firestore
    await _db.collection('bulk_import_batches').doc(batchId).set({
      'isRolledBack': true,
      'rolledBackAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Deletes a Cloudinary image using its delete_token
  Future<void> _deleteCloudinaryImageByToken(String deleteToken) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/delete_by_token');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': deleteToken}),
    );
  }

  /// Stream of past bulk import history
  Stream<List<BulkImportBatchModel>> watchBatchHistory() {
    return _db
        .collection('bulk_import_batches')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BulkImportBatchModel.fromFirestore(d)).toList());
  }
}

class _StatusStats {
  int count = 0;
  int totalItems = 0;
  int totalPaise = 0;
}

class ProductConflict {
  final ProductModel existingProduct;
  final ProductModel importedProduct;

  ProductConflict({
    required this.existingProduct,
    required this.importedProduct,
  });
}

class BulkImportResult {
  final List<ProductModel> validProducts;
  final List<ProductConflict> duplicates;
  final List<CategoryModel> autoCreatedCategories;
  final List<BrandModel> autoCreatedBrands;
  final List<String> errors;

  BulkImportResult({
    required this.validProducts,
    required this.duplicates,
    required this.autoCreatedCategories,
    required this.autoCreatedBrands,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasDuplicates => duplicates.isNotEmpty;
  bool get hasValidProducts => validProducts.isNotEmpty;
  int get totalReadyCount => validProducts.length + duplicates.length;
}

