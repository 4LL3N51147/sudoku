// Stub export for non-web platforms
// On web, this file is replaced by web_export.dart

void downloadJson(String jsonString, String filename) {
  // No-op on non-web platforms - print to console for debugging
  // ignore: avoid_print
  print('Export to file not supported on this platform');
  // ignore: avoid_print
  print('JSON: $jsonString');
}
