import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/bill_dao.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class BillPreviewScreen extends ConsumerStatefulWidget {
  final BillData billData;
  final BillTemplatesCompanion template;

  const BillPreviewScreen({
    super.key,
    required this.billData,
    required this.template,
  });

  @override
  ConsumerState<BillPreviewScreen> createState() => _BillPreviewScreenState();
}

class _BillPreviewScreenState extends ConsumerState<BillPreviewScreen> {
  bool _isGenerating = false;

  Future<void> _saveBill() async {
    setState(() => _isGenerating = true);
    
    try {
      final dao = ref.read(billDaoProvider);
      await dao.insert(widget.billData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill saved successfully')),
        );
        context.go('/billing/history');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving bill: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _shareWhatsApp() async {
    final phone = widget.billData.phone;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customer phone number')),
      );
      return;
    }

    final message = _buildWhatsAppMessage();
    final url = Uri.parse('whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp not available')),
      );
    }
  }

  String _buildWhatsAppMessage() {
    final sb = StringBuffer();
    sb.writeln('*${widget.template.brandName}*');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('Bill #${DateTime.now().millisecondsSinceEpoch}');
    sb.writeln('Date: ${_formatDate(DateTime.now())}');
    if (widget.billData.customerName.isNotEmpty) {
      sb.writeln('Customer: ${widget.billData.customerName}');
    }
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    
    for (var item in widget.billData.items) {
      sb.writeln('${item.name} x${item.quantity}');
      sb.writeln('  ₹${item.subtotal.toStringAsFixed(2)}');
    }
    
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('Subtotal: ₹${widget.billData.subtotal.toStringAsFixed(2)}');
    if (widget.billData.discountValue > 0) {
      sb.writeln('Discount: -₹${_calculateDiscount().toStringAsFixed(2)}');
    }
    sb.writeln('*Total: ₹${widget.billData.total.toStringAsFixed(2)}*');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('Thank you for your visit!');
    
    return sb.toString();
  }

  double _calculateDiscount() {
    if (widget.billData.discountType == 'percent') {
      return widget.billData.subtotal * (widget.billData.discountValue / 100);
    }
    return widget.billData.discountValue;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _printBill() async {
    final pdf = await _generatePdf();
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<pw.Document> _generatePdf() async {
    final doc = pw.Document();
    
    // Load logo if available
    pw.ImageProvider? logoImage;
    if (widget.template.logoPath.isNotEmpty && File(widget.template.logoPath).existsSync()) {
      logoImage = pw.MemoryImage(File(widget.template.logoPath).readAsBytesSync());
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Image(logoImage!, width: 100, height: 100),
              
              pw.SizedBox(height: 10),
              
              pw.Text(
                widget.template.brandName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex(_hexFromColor(widget.template.primaryColor)),
                ),
              ),
              
              if (widget.template.footerText.isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Text(
                  widget.template.footerText,
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              
              pw.SizedBox(height: 20),
              
              pw.Divider(),
              
              pw.SizedBox(height: 10),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill #${DateTime.now().millisecondsSinceEpoch}'),
                  pw.Text(_formatDate(DateTime.now())),
                ],
              ),
              
              if (widget.billData.customerName.isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Text('Customer: ${widget.billData.customerName}'),
              ],
              
              if (widget.billData.phone.isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Text('Phone: ${widget.billData.phone}'),
              ],
              
              pw.SizedBox(height: 20),
              
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex(_hexFromColor(widget.template.primaryColor)).withAlpha(50),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  ...widget.billData.items.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.name),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${item.price.toStringAsFixed(2)}', textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${item.subtotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.right),
                      ),
                    ],
                  )),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              pw.Divider(),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.SizedBox(
                            width: 150,
                            child: pw.Text('Subtotal:', textAlign: pw.TextAlign.right),
                          ),
                          pw.SizedBox(
                            width: 100,
                            child: pw.Text('₹${widget.billData.subtotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.right),
                          ),
                        ],
                      ),
                      if (_calculateDiscount() > 0) ...[
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.SizedBox(
                              width: 150,
                              child: pw.Text('Discount:', textAlign: pw.TextAlign.right),
                            ),
                            pw.SizedBox(
                              width: 100,
                              child: pw.Text('-₹${_calculateDiscount().toStringAsFixed(2)}', textAlign: pw.TextAlign.right),
                            ),
                          ],
                        ),
                      ],
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.SizedBox(
                            width: 150,
                            child: pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                          ),
                          pw.SizedBox(
                            width: 100,
                            child: pw.Text('₹${widget.billData.total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.Spacer(),
              
              pw.Divider(),
              
              pw.SizedBox(height: 10),
              
              pw.Text(
                'Thank you for your visit!',
                style: const pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );

    return doc;
  }

  String _hexFromColor(int color) {
    return '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isGenerating ? null : _saveBill,
            tooltip: 'Save Bill',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareWhatsApp,
            tooltip: 'Share via WhatsApp',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printBill,
            tooltip: 'Print',
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: AppCard(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          if (widget.template.logoPath.isNotEmpty && File(widget.template.logoPath).existsSync())
                            Image.file(
                              File(widget.template.logoPath),
                              height: 80,
                              width: 80,
                            ),
                          const SizedBox(height: 8),
                          Text(
                            widget.template.brandName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(widget.template.primaryColor),
                            ),
                          ),
                          if (widget.template.footerText.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.template.footerText,
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bill #${DateTime.now().millisecondsSinceEpoch}'),
                        Text(_formatDate(DateTime.now())),
                      ],
                    ),
                    if (widget.billData.customerName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Customer: ${widget.billData.customerName}'),
                    ],
                    if (widget.billData.phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Phone: ${widget.billData.phone}'),
                    ],
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Item')),
                            DataColumn(label: Text('Qty', textAlign: TextAlign.center)),
                            DataColumn(label: Text('Price', textAlign: TextAlign.right)),
                            DataColumn(label: Text('Total', textAlign: TextAlign.right)),
                          ],
                          rows: widget.billData.items.map((item) {
                            return DataRow(cells: [
                              DataCell(Text(item.name)),
                              DataCell(Text('${item.quantity}', textAlign: TextAlign.center)),
                              DataCell(Text('₹${item.price.toStringAsFixed(2)}', textAlign: TextAlign.right)),
                              DataCell(Text('₹${item.subtotal.toStringAsFixed(2)}', textAlign: TextAlign.right)),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal', '₹${widget.billData.subtotal.toStringAsFixed(2)}'),
                          if (_calculateDiscount() > 0)
                            _buildSummaryRow('Discount', '-₹${_calculateDiscount().toStringAsFixed(2)}'),
                          _buildSummaryRow(
                            'Total',
                            '₹${widget.billData.total.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Thank you for your visit!',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 18 : 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 18 : 14,
                color: isTotal ? Theme.of(context).primaryColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
