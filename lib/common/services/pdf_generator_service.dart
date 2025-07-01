import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGeneratorService {
  static Future<Uint8List> generateAttendancePdf(
      String title, List<String> headers, List<List<String>> data) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(title, font),
            _buildTable(headers, data, font),
          ];
        },
        footer: (pw.Context context) {
          return _buildFooter(context, font);
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String title, pw.Font font) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Text(
        title,
        style: pw.TextStyle(
            font: font, fontSize: 22, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildTable(
      List<String> headers, List<List<String>> data, pw.Font font) {
    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(
        font: font,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blueGrey700,
      ),
      cellStyle: pw.TextStyle(font: font),
      cellAlignment: pw.Alignment.center,
      cellAlignments: {
        0: pw.Alignment.centerLeft, // Align first column (e.g., Name) to the left
      },
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font font) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(font: font, color: PdfColors.grey),
      ),
    );
  }
} 