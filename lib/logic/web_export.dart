// Export helpers for web platform
// This file is only imported when running on web

import 'dart:html' show AnchorElement, Blob, Url;

void downloadJson(String jsonString, String filename) {
  final blob = Blob([jsonString], 'application/json');
  final url = Url.createObjectUrlFromBlob(blob);
  AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  // Delay revocation slightly to ensure download initiates
  Future.delayed(const Duration(milliseconds: 100), () => Url.revokeObjectUrl(url));
}
