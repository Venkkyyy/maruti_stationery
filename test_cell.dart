import 'dart:io';
import 'package:excel_plus/excel_plus.dart';

void main() {
  final bytes = File('/Users/avantikahiranandani/Downloads/Maruti_Bulk_Product_Template_Filled.xlsx').readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  final sheet = excel.tables['Products']!;
  for (int i = 0; i < 2; i++) {
    final row = sheet.rows[i];
    for (final c in row.take(6)) {
      print('Type: ${c?.value.runtimeType}, toString: "${c?.value?.toString()}"');
    }
  }
}

