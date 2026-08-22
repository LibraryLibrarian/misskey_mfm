import 'dart:io';

import 'package:test/test.dart';

import '../../tool/src/release_project.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('mfm_parser_release_tools_');
    _createProject(root);
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  test('bumpVersion updates pubspec.yaml and CHANGELOG.md', () {
    final updatedPaths = bumpVersion(
      root,
      '1.0.0-beta.4',
      releaseDate: DateTime.utc(2026, 8, 13),
    );

    expect(_read(root, 'pubspec.yaml'), contains('version: 1.0.0-beta.4'));
    expect(
      _read(root, 'CHANGELOG.md'),
      contains(
        '## [Unreleased]\n\n'
        '## [1.0.0-beta.4] - 2026-08-13\n\n'
        '### Added',
      ),
    );
    expect(updatedPaths, <String>['pubspec.yaml', 'CHANGELOG.md']);
    expect(() => verifyRelease(root, '1.0.0-beta.4'), returnsNormally);
  });

  test('bumpVersion does not write files when CHANGELOG is invalid', () {
    _write(root, 'CHANGELOG.md', '# Changelog\n');
    final originalPubspec = _read(root, 'pubspec.yaml');

    expect(
      () => bumpVersion(root, '1.0.0-beta.4'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          contains('Unreleased'),
        ),
      ),
    );
    expect(_read(root, 'pubspec.yaml'), originalPubspec);
  });

  test('verifyRelease rejects a mismatched pubspec version', () {
    expect(
      () => verifyRelease(root, '1.0.0-beta.2'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          contains('pubspec.yaml has version'),
        ),
      ),
    );
  });

  test('verifyRelease rejects an invalid CHANGELOG date', () {
    final changelog = _read(
      root,
      'CHANGELOG.md',
    ).replaceFirst('2026-08-05', '2026-02-30');
    _write(root, 'CHANGELOG.md', changelog);

    expect(
      () => verifyRelease(root, '1.0.0-beta.3'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          contains('invalid release date'),
        ),
      ),
    );
  });

  test('extractReleaseNotes returns only the requested release body', () {
    final notes = extractReleaseNotes(root, '1.0.0-beta.3');

    expect(notes, '### Added\n\n- Released change\n');
    expect(notes, isNot(contains('Pending change')));
    expect(notes, isNot(contains('1.0.0-beta.2')));
  });

  test('extractReleaseNotes rejects a release without notes', () {
    _write(
      root,
      'CHANGELOG.md',
      '# Changelog\n\n'
          '## [Unreleased]\n\n'
          '## [1.0.0-beta.3] - 2026-08-05\n\n'
          '## [1.0.0-beta.2] - 2026-07-01\n\n'
          '### Fixed\n\n'
          '- Older change\n',
    );

    expect(
      () => extractReleaseNotes(root, '1.0.0-beta.3'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          contains('no release notes'),
        ),
      ),
    );
  });

  test('release tools reject invalid Semantic Versions', () {
    expect(
      () => bumpVersion(root, '1.0'),
      throwsA(isA<ReleaseToolException>()),
    );
    expect(
      () => verifyRelease(root, '1.0.0-01'),
      throwsA(isA<ReleaseToolException>()),
    );
  });

  test('readPubspecVersion returns a validated version', () {
    expect(readPubspecVersion(root), '1.0.0-beta.3');

    _write(root, 'pubspec.yaml', 'version: development\n');
    expect(
      () => readPubspecVersion(root),
      throwsA(isA<ReleaseToolException>()),
    );
  });
}

void _createProject(Directory root) {
  _write(
    root,
    'pubspec.yaml',
    'name: misskey_mfm_parser\n'
        'version: 1.0.0-beta.3\n',
  );
  _write(
    root,
    'CHANGELOG.md',
    '# Changelog\n\n'
        '## [Unreleased]\n\n'
        '### Added\n\n'
        '- Pending change\n\n'
        '## [1.0.0-beta.3] - 2026-08-05\n\n'
        '### Added\n\n'
        '- Released change\n\n'
        '## [1.0.0-beta.2] - 2026-07-01\n\n'
        '### Fixed\n\n'
        '- Older change\n',
  );
}

void _write(Directory root, String path, String content) {
  final file = File.fromUri(root.uri.resolve(path));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

String _read(Directory root, String path) =>
    File.fromUri(root.uri.resolve(path)).readAsStringSync();
