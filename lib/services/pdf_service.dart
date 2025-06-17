// lib/services/pdf_service.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import '../model/contract_model.dart';

class PdfService {
  static Future<Uint8List> generateContractPdf(ContractModel contract) async {
    final pdf = pw.Document();

    // Load Arabic font
    final arabicFont =
        pw.Font.ttf(await rootBundle.load("assets/fonts/Almarai-Regular.ttf"));
    final arabicFontBold =
        pw.Font.ttf(await rootBundle.load("assets/fonts/Almarai-Bold.ttf"));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (context) => [
          _buildHeader(arabicFontBold),
          pw.SizedBox(height: 20),
          _buildContractTitle(arabicFontBold),
          pw.SizedBox(height: 20),
          _buildContractInfo(contract, arabicFont),
          pw.SizedBox(height: 20),
          _buildPartyDetails(contract, arabicFont, arabicFontBold),
          pw.SizedBox(height: 20),
          _buildBoatDetails(contract, arabicFont, arabicFontBold),
          pw.SizedBox(height: 20),
          _buildEngineDetails(contract, arabicFont, arabicFontBold),
          pw.SizedBox(height: 20),
          _buildEquipmentDetails(contract, arabicFont, arabicFontBold),
          pw.SizedBox(height: 20),
          _buildSaleDetails(contract, arabicFont, arabicFontBold),
          pw.SizedBox(height: 20),
          _buildTermsAndConditions(contract, arabicFont, arabicFontBold),
          pw.SizedBox(height: 30),
          _buildSignatureSection(contract, arabicFont, arabicFontBold),
          pw.SizedBox(height: 30),
          _buildCompanyStamp(arabicFont, arabicFontBold),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SAILING UNITED',
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
              pw.Text('Tel.0557150151 C.R 4602116244'),
              pw.Text('Rabigh - Kingdom of Saudi Arabia'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'مؤسسة أبحر المتحدة التجارية',
                style: pw.TextStyle(font: boldFont, fontSize: 14),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'س.ت 4602116244 هاتف 0557150151',
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'رابغ - المملكة العربية السعودية',
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildContractTitle(pw.Font boldFont) {
    return pw.Center(
      child: pw.Text(
        'عقد مبايعة واسطة بحرية',
        style: pw.TextStyle(font: boldFont, fontSize: 20),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  static pw.Widget _buildContractInfo(ContractModel contract, pw.Font font) {
    final hijriDate = _convertToHijri(contract.saleDate);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          'إنه في يوم: ${DateFormat('EEEE', 'ar').format(contract.saleDate)} تاريخ: $hijriDate هـ الموافق ${DateFormat('dd/MM/yyyy').format(contract.saleDate)} م برقم العقد: ${contract.contractNumber} تم الاتفاق بين:',
          style: pw.TextStyle(font: font),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  static pw.Widget _buildPartyDetails(
    ContractModel contract,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      children: [
        // Seller table
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                _buildTableCell('الجنسية', font),
                _buildTableCell('نسبة التملك', font),
                _buildTableCell('تاريخ الانتهاء', font),
                _buildTableCell('رقم الهوية', font),
                _buildTableCell('الطرف الأول البائع / الاسم', font),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell(
                    contract.sellerDetails['nationality'] ?? 'سعودي', font),
                _buildTableCell('100%', font),
                _buildTableCell(contract.sellerDetails['idExpiry'] ?? '', font),
                _buildTableCell(contract.sellerDetails['idNumber'] ?? '', font),
                _buildTableCell(
                    'السيد / ${contract.sellerDetails['name'] ?? ''}', font),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        // Buyer table
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                _buildTableCell('الجنسية', font),
                _buildTableCell('نسبة التملك', font),
                _buildTableCell('تاريخ الانتهاء', font),
                _buildTableCell('رقم الهوية', font),
                _buildTableCell('الطرف الثاني / المشتري', font),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell(
                    contract.buyerDetails['nationality'] ?? 'سعودي', font),
                _buildTableCell('100%', font),
                _buildTableCell(contract.buyerDetails['idExpiry'] ?? '', font),
                _buildTableCell(contract.buyerDetails['idNumber'] ?? '', font),
                _buildTableCell(
                    'السيد / ${contract.buyerDetails['name'] ?? ''}', font),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildBoatDetails(
    ContractModel contract,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          'فقد اتفق كلا الطرفين على الآتي:',
          style: pw.TextStyle(font: font),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.Text(
          'أولاً: باع الطرف الأول للطرف الثاني الوحدة البحرية ومواصفاتها كالآتي:',
          style: pw.TextStyle(font: boldFont),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            _buildBoatDetailRow('اسم الوحدة:', contract.boatDetails.vesselName,
                'رقم القيد:', contract.boatDetails.registrationNumber, font),
            _buildBoatDetailRow(
                'تاريخ القيد:',
                contract.boatDetails.registrationDate != null
                    ? DateFormat('dd/MM/yyyy')
                        .format(contract.boatDetails.registrationDate!)
                    : '',
                'طبيعة العمل:',
                contract.boatDetails.workNature,
                font),
            _buildBoatDetailRow('الطول:', '${contract.boatDetails.length}م',
                'العرض:', '${contract.boatDetails.width} م', font),
            _buildBoatDetailRow('العمق:', '${contract.boatDetails.depth}م',
                'الحمولة:', '${contract.boatDetails.capacity} طن', font),
            _buildBoatDetailRow(
                'مادة البناء:',
                contract.boatDetails.buildMaterial,
                'منطقة العمل:',
                contract.boatDetails.workArea,
                font),
            _buildBoatDetailRow(
                'رقم الهيكل:',
                contract.boatDetails.hullNumber,
                'عدد الركاب:',
                contract.boatDetails.passengerCount.toString(),
                font),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildEngineDetails(
    ContractModel contract,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < contract.boatDetails.engines.length; i++)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'الرقم التسلسلي: ${contract.boatDetails.engines[i].serialNumber}',
                style: pw.TextStyle(font: font),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(width: 20),
              pw.Text(
                'قدرتها بالحصان: ${contract.boatDetails.engines[i].horsepower}',
                style: pw.TextStyle(font: font),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(width: 20),
              pw.Text(
                'نوع المحرك: ${contract.boatDetails.engines[i].type}',
                style: pw.TextStyle(font: font),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildEquipmentDetails(
    ContractModel contract,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          'ثانياً: الأجهزة حيث تتضمن على الآتي:',
          style: pw.TextStyle(font: boldFont),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                _buildTableCell('جهاز الأعماق', font),
                _buildTableCell('EPIRB جهاز الاستغاثة', font),
                _buildTableCell('VHF جهاز اللاسلكي', font),
                _buildTableCell('AIS جهاز التتبع', font),
                _buildTableCell('إشارة النداء', font),
                _buildTableCell('رقم الهوية البحرية', font),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell(
                    contract.boatDetails.equipment.hasDepthFinder ? '✓' : '✗',
                    font),
                _buildTableCell(
                    contract.boatDetails.equipment.hasEPIRB ? '✓' : '✗', font),
                _buildTableCell(
                    contract.boatDetails.equipment.hasVHF ? '✓' : '✗', font),
                _buildTableCell(
                    contract.boatDetails.equipment.hasAIS ? '✓' : '✗', font),
                _buildTableCell(contract.boatDetails.equipment.callSign, font),
                _buildTableCell(contract.boatDetails.equipment.marineId, font),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSaleDetails(
    ContractModel contract,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          'ثالثاً: قيمة شراء الوحدة البحرية مقابل مبلغ وقدره (${NumberFormat('#,###').format(contract.saleAmount)}) ${contract.saleAmountText}.',
          style: pw.TextStyle(font: boldFont),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  static pw.Widget _buildTermsAndConditions(
    ContractModel contract,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final terms = [
      'رابعاً: إقرار بتحمل الطرف الأول كامل المسؤولية والوقوف على الوحدة المذكورة مع الجهات ذات العلاقة وتعتبر هذه المبايعة اثبات فقط للبيع ولا نتحمل أي مسؤولية عن أي خلاف يحصل بين أطرافها.',
      'خامساً: وافق الطرف الثاني على شراء الوحدة البحرية المشار إليها وبالتالي أصبحت ملكاً خالصاً له دون أي معارضة من أحد وقد تمت المعاينة والاستلام بحالتها الراهنة.',
      'سادساً: يتعهد الطرف الأول بالقيام بكافة الإجراءات النظامية نحو نقل ملكية الوحدة البحرية بالهيئة العامة للنقل خلال عشرة أيام من تاريخ البيع ويلتزم بدفع كافة الرسوم والغرامات في حالة تأخره في نقل الملكية إن وجدت.',
      'سابعاً: يتعهد الطرف الأول بأن الوحدة البحرية المذكورة مواصفاتها أعلاه ليست مرهونة أو متنازع عليها، ويتحمل كامل المسؤولية أمام أصحاب الحقوق العينية والمتنازعين على ما تم بيعه بالمواصفات الموضحة أعلاه وعن أي اختلاف أو خلاف ينتج عن نقل الملكية.',
      'ثامناً: قد تسلم الطرف الأول كامل قيمة شراء الوحدة البحرية المشار إليها أعلاه كما أن الطرف الثاني تسلم الوحدة البحرية وبها كافة التجهيزات المذكورة في العقد وتمت مطابقتها طبقاً لما هو مدون في سند الملك ورخصة العمل ورخصة الأجهزة.',
      'تاسعاً: يلتزم محرر العقد بأن جميع ما ورد أعلاه نظامي وتحت إشرافه ويتحمل أي التزام يترتب خلاف ذلك وأنه تم معاينة الوحدة البحرية المذكورة وأن الهيئة العامة للنقل لا تتحمل المسؤولية تجاه الأطراف المذكورة بهذا الشأن.',
      'عاشراً: حرر هذا العقد برغبة الطرفين بكامل إرادتهما وتم الاتفاق على بيع ما ذكر أعلاه وجرى التوقيع على ذلك.',
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: terms
          .map((term) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  term,
                  style: pw.TextStyle(font: font),
                  textDirection: pw.TextDirection.rtl,
                ),
              ))
          .toList(),
    );
  }

  static pw.Widget _buildSignatureSection(
    ContractModel contract,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            _buildSignatureBox('المشتري (الطرف الثاني)',
                contract.buyerDetails['name'] ?? '', font, boldFont),
            _buildSignatureBox('البائع (الطرف الأول)',
                contract.sellerDetails['name'] ?? '', font, boldFont),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'شهد بذلك:',
          style: pw.TextStyle(font: boldFont),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            _buildWitnessBox('اسم الشاهد الثاني:', font),
            _buildWitnessBox('اسم الشاهد الأول:', font),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCompanyStamp(pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'نصادق على صحة توقيع البائع والمشتري والشهود بعد أن تم التوقيع أمامنا وذلك بعد التأكد من هوياتهم وبدون أي مسؤولية تقع علينا تجاه محتويات العقد، ويعتبر هذا التصديق موافقة مبدئية لإكمال الإجراءات النظامية لنقل الملكية لدى الجهة المختصة.',
            style: pw.TextStyle(font: font),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'مؤسسة أبحر المتحدة التجارية',
              style: pw.TextStyle(font: boldFont),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Text('الختم:              ',
                  textDirection: pw.TextDirection.rtl),
              pw.Text('التوقيع:              ',
                  textDirection: pw.TextDirection.rtl),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  static pw.Widget _buildTableCell(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font),
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.TableRow _buildBoatDetailRow(String label1, String value1,
      String label2, String value2, pw.Font font) {
    return pw.TableRow(
      children: [
        _buildTableCell(value2, font),
        _buildTableCell(label2, font),
        _buildTableCell(value1, font),
        _buildTableCell(label1, font),
      ],
    );
  }

  static pw.Widget _buildSignatureBox(
      String title, String name, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      width: 200,
      child: pw.Column(
        children: [
          pw.Text(title,
              style: pw.TextStyle(font: boldFont),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 5),
          pw.Text('السيد / $name',
              style: pw.TextStyle(font: font),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 5),
          pw.Text('التوقيع / __________',
              style: pw.TextStyle(font: font),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 5),
          pw.Text('ملاحظات:',
              style: pw.TextStyle(font: font),
              textDirection: pw.TextDirection.rtl),
        ],
      ),
    );
  }

  static pw.Widget _buildWitnessBox(String title, pw.Font font) {
    return pw.Container(
      width: 200,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(title,
              style: pw.TextStyle(font: font),
              textDirection: pw.TextDirection.rtl),
          pw.Text('رقم الهوية:',
              style: pw.TextStyle(font: font),
              textDirection: pw.TextDirection.rtl),
          pw.Text('التوقيع:',
              style: pw.TextStyle(font: font),
              textDirection: pw.TextDirection.rtl),
        ],
      ),
    );
  }

  static String _convertToHijri(DateTime date) {
    // This is a simplified conversion - in production you'd use a proper Hijri conversion library
    // For now, returning a placeholder
    return '${date.day}/${date.month}/1446';
  }
}
