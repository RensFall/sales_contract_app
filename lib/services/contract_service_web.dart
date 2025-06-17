// lib/services/contract_service_web.dart
import 'dart:html' as html;

Future<void> downloadFile(String url, String fileName) async {
  try {
    // Web download implementation
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
  } catch (e) {
    print('Error downloading file on web: $e');
    throw Exception('Failed to download file: $e');
  }
}
