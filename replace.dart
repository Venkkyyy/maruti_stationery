import 'dart:io';

void main() {
  final dir = Directory('lib');
  int count = 0;
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final content = file.readAsStringSync();
      if (content.contains('.withOpacity(')) {
        final newContent = content.replaceAll('.withOpacity(', '.withValues(alpha: ');
        file.writeAsStringSync(newContent);
        count++;
        print('Updated: ${file.path}');
      }
    }
  }
  print('Total files updated: $count');
}
