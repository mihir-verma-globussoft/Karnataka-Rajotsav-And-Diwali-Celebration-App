import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the dependency rules in docs/ARCHITECTURE.md.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  Iterable<String> importsOf(File f) =>
      RegExp(r'''import\s+['"]([^'"]+)['"]''')
          .allMatches(f.readAsStringSync())
          .map((m) => m.group(1)!);

  String norm(File f) => f.path.replaceAll(r'\', '/');

  test('core never imports app or features', () {
    for (final f in files.where((f) => norm(f).startsWith('lib/core/'))) {
      for (final i in importsOf(f)) {
        expect(
          i.contains('/app/') ||
              i.contains('/features/') ||
              i.startsWith('../app') ||
              i.startsWith('../features'),
          isFalse,
          reason: '${f.path} imports $i',
        );
      }
    }
  });

  test('domain layers stay free of Flutter and data/presentation', () {
    for (final f in files.where((f) => norm(f).contains('/domain/'))) {
      for (final i in importsOf(f)) {
        expect(
          i.startsWith('package:flutter/'),
          isFalse,
          reason: '${f.path} imports $i',
        );
        expect(
          i.contains('/data/') || i.contains('/presentation/'),
          isFalse,
          reason: '${f.path} imports $i',
        );
      }
    }
  });

  test('presentation never imports data layers', () {
    for (final f in files.where((f) => norm(f).contains('/presentation/'))) {
      for (final i in importsOf(f)) {
        expect(i.contains('/data/'), isFalse, reason: '${f.path} imports $i');
      }
    }
  });

  test('features do not import other features internals', () {
    final featureDir = RegExp(r'lib/features/([^/]+)/');
    for (final f in files) {
      final own = featureDir.firstMatch(norm(f))?.group(1);
      if (own == null) continue;
      for (final i in importsOf(f)) {
        final other = RegExp(r'features/([^/]+)/').firstMatch(i)?.group(1);
        if (other == null || other == own) continue;
        // Only another feature's public `<name>_feature.dart` may be imported.
        expect(
          i.endsWith('${other}_feature.dart'),
          isTrue,
          reason: '${f.path} imports $i',
        );
      }
    }
  });

  test('features import only the public parts of app/', () {
    const allowed = ['feature_module.dart', 'providers.dart'];
    for (final f in files.where((f) => norm(f).startsWith('lib/features/'))) {
      for (final i in importsOf(f)) {
        if (!i.contains('app/')) continue;
        expect(allowed.any(i.endsWith), isTrue, reason: '${f.path} imports $i');
      }
    }
  });
}
