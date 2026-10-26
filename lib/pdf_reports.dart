import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SheetStudent {
  final int? seat;
  final String name, className, gender;
  final int? committee;
  SheetStudent(this.seat, this.name, this.className, this.gender,
      [this.committee]);
}

class CommitteeSheet {
  final int no;
  final String className;
  final List<SheetStudent> students;
  CommitteeSheet(this.no, this.className, this.students);
}

Future<pw.ThemeData> _theme() async {
  final r = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
  final b = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
  return pw.ThemeData.withFont(base: r, bold: b);
}

pw.Widget _t(String s,
        {double size = 11,
        bool bold = false,
        pw.TextAlign align = pw.TextAlign.center}) =>
    pw.Text(s,
        textDirection: pw.TextDirection.rtl,
        textAlign: align,
        style: pw.TextStyle(
            fontSize: size,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal));

pw.Widget _cell(String s, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
    child: _t(s, bold: bold, size: 10));

/// يعرض الأعمدة من اليمين لليسار بعكس ترتيبها المنطقي.
List<T> _rtl<T>(List<T> l) => l.reversed.toList();

pw.Widget _header(String school, String year) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: _rtl([
        pw.Column(children: [
          _t('الجمهورية اليمنية', bold: true),
          _t('وزارة التربية والتعليم'),
        ]),
        _t('بسم الله الرحمن الرحيم', bold: true, size: 12),
        pw.Column(children: [
          _t('المدرسة: ${school.isEmpty ? '................' : school}'),
          _t('العام الدراسي: $year'),
        ]),
      ]),
    );

pw.Widget _signatures() => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: _rtl([
        _t('رئيس الكنترول: ...............'),
        _t('مدير المدرسة: ...............'),
      ]),
    );

/// كشوف مناداة الطلاب في اللجان: صفحة لكل لجنة.
Future<Uint8List> buildCallSheets(
    List<CommitteeSheet> sheets, String school, String year) async {
  final doc = pw.Document(theme: await _theme());
  for (final sh in sheets) {
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (_) => pw.Column(children: [
        _header(school, year),
        pw.SizedBox(height: 10),
        _t('كشف مناداة الطلاب في اللجنة (${sh.no}) - ${sh.className}',
            bold: true, size: 14),
        pw.SizedBox(height: 8),
      ]),
      footer: (_) => _signatures(),
      build: (_) {
        const heads = ['م', 'اسم الطالب', 'رقم الجلوس', 'التوقيع', 'الحالة', 'ملاحظات'];
        final widths = _rtl([
          const pw.FixedColumnWidth(24),
          const pw.FlexColumnWidth(4),
          const pw.FixedColumnWidth(60),
          const pw.FlexColumnWidth(2),
          const pw.FixedColumnWidth(60),
          const pw.FlexColumnWidth(2),
        ]);
        return [
          pw.Table(
            border: pw.TableBorder.all(width: 0.6),
            columnWidths: {for (var i = 0; i < widths.length; i++) i: widths[i]},
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: _rtl([for (final h in heads) _cell(h, bold: true)]),
              ),
              for (var i = 0; i < sh.students.length; i++)
                pw.TableRow(
                  children: _rtl([
                    _cell('${i + 1}'),
                    _cell(sh.students[i].name),
                    _cell('${sh.students[i].seat ?? '-'}'),
                    _cell(''),
                    _cell('حاضر / غائب'),
                    _cell(''),
                  ]),
                ),
            ],
          ),
        ];
      },
    ));
  }
  return doc.save();
}

/// بطاقات أرقام الجلوس (10 بطاقات في الصفحة).
Future<Uint8List> buildSeatCards(
    List<SheetStudent> students, String school, String year) async {
  final doc = pw.Document(theme: await _theme());
  for (var start = 0; start < students.length; start += 10) {
    final chunk = students.skip(start).take(10).toList();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => pw.GridView(
        crossAxisCount: 2,
        childAspectRatio: 2.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: [
          for (final s in chunk)
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.8),
                  borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  _t('بطاقة رقم جلوس - ${school.isEmpty ? '' : school}',
                      bold: true, size: 10),
                  _t(s.name, bold: true, size: 12),
                  _t('رقم الجلوس: ${s.seat ?? '-'}', size: 12, bold: true),
                  _t('${s.className}   •   اللجنة: ${s.committee ?? '-'}',
                      size: 10),
                  _t(year, size: 9),
                ],
              ),
            ),
        ],
      ),
    ));
  }
  if (students.isEmpty) doc.addPage(pw.Page(build: (_) => _t('لا يوجد طلاب')));
  return doc.save();
}

Future<void> printPdf(Uint8List bytes, String name) =>
    Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
