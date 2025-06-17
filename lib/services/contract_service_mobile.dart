// lib/services/contract_service_mobile.dart
import 'package:url_launcher/url_launcher.dart';

Future<void> downloadFile(String url, String fileName) async {
  try {
    // Mobile download implementation - use url_launcher
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  } catch (e) {
    print('Error downloading file on mobile: $e');
    throw Exception('Failed to download file: $e');
  }
}
