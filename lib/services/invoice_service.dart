import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../core/utils/formatters.dart';

class InvoiceService {
  static Future<void> generateAndPrintInvoice(OrderModel order) async {
    final pdf = pw.Document();
    
    // Load font if needed (printing uses default font if not specified, but for Rupee symbol we might need a specific font. 
    // For now, we can just use "Rs." instead of "₹" in PDF to avoid font issues, or load a font.)
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(order),
            pw.SizedBox(height: 20),
            _buildAddress(order),
            pw.SizedBox(height: 20),
            _buildItemsTable(order),
            pw.SizedBox(height: 20),
            _buildTotal(order),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${order.id}.pdf',
    );
  }

  static pw.Widget _buildHeader(OrderModel order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('MARUTI STATIONERY', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Order ID: ${order.id}'),
            pw.Text('Date: ${DateFormat('dd MMM yyyy').format(order.createdAt)}'),
          ],
        ),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildAddress(OrderModel order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 4),
        pw.Text(order.address.name),
        pw.Text(order.address.street),
        pw.Text('${order.address.city}, ${order.address.state} ${order.address.pincode}'),
        pw.Text('Phone: ${order.address.phone}'),
      ],
    );
  }

  static pw.Widget _buildItemsTable(OrderModel order) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headers: ['Item', 'Qty', 'Unit Price', 'Total'],
      data: [
        ...order.items.map((item) => [
          item.name,
          item.qty.toString(),
          'Rs. ${(item.price / 100).toStringAsFixed(2)}',
          'Rs. ${(item.total / 100).toStringAsFixed(2)}',
        ]),
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      cellAlignment: pw.Alignment.centerRight,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
      },
    );
  }

  static pw.Widget _buildTotal(OrderModel order) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Subtotal:'),
              pw.Text('Delivery:'),
              if (order.discount > 0) pw.Text('Discount:'),
              pw.SizedBox(height: 8),
              pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            ],
          ),
          pw.SizedBox(width: 20),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Rs. ${(order.subtotal / 100).toStringAsFixed(2)}'),
              pw.Text('Rs. ${(order.deliveryCharge / 100).toStringAsFixed(2)}'),
              if (order.discount > 0) pw.Text('- Rs. ${(order.discount / 100).toStringAsFixed(2)}'),
              pw.SizedBox(height: 8),
              pw.Text('Rs. ${(order.total / 100).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
