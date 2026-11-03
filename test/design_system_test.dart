import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces docs/DESIGN_SYSTEM.md: outside `lib/core/theme/`, UI code uses
/// design tokens (`AppSpacing`, `AppSizes`, `AppColors`…) or `colorScheme`
/// roles, never hard-coded colours, sizes, radii or opacities.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.replaceAll(r'\', '/').startsWith('lib/core/theme/'))
      .toList();

  final rules = <String, RegExp>{
    'hard-coded colour (use AppColors or colorScheme)': RegExp(
      r'Color\(0x|Color\.from(ARGB|RGBO)|\bColors\.',
    ),
    'hard-coded size (use AppSizes / AppIconSizes / AppSpacing)': RegExp(
      r'\b(size|fontSize|width|height|minWidth|maxWidth|minHeight|maxHeight|'
      r'elevation|spacing|runSpacing|mainAxisSpacing|crossAxisSpacing|'
      r'mainAxisExtent|maxCrossAxisExtent|strokeWidth)\s*:\s*0*[1-9]',
    ),
    'hard-coded padding (use AppSpacing)': RegExp(
      r'EdgeInsets\.\w+\((\s*0*[1-9]|[^)]*[,(]\s*0*[1-9])',
    ),
    'hard-coded radius (use AppRadius)': RegExp(r'circular\(\s*0*[1-9]'),
    'hard-coded opacity (use AppOpacity)': RegExp(
      r'alpha:\s*0?\.\d|withOpacity\(',
    ),
    'hard-coded duration (use AppDurations)': RegExp(
      r'duration:\s*(const\s+)?Duration\(',
    ),
  };

  for (final entry in rules.entries) {
    test('no ${entry.key}', () {
      final offences = <String>[];
      for (final f in files) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final code = lines[i].split('//').first;
          if (entry.value.hasMatch(code)) {
            offences.add('${f.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
      expect(offences, isEmpty, reason: offences.join('\n'));
    });
  }
}
