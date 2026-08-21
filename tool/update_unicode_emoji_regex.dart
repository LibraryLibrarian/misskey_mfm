import 'dart:convert';
import 'dart:io';

/// Regenerates the Unicode emoji regular expression used by the parser.
///
/// Run this command from the repository root:
///
/// ```sh
/// dart run tool/update_unicode_emoji_regex.dart
/// ```
///
/// To update Unicode, advance the version and pinned upstream revision below,
/// then review both the generated diff and the Unicode emoji regression tests.
const unicodeVersion = '17.0';
const sourceRevision = '05a4771881f9673b7b0b5ded8ca7ecc03244c82a';
const sourceBlob = '80cc7d7247cd0d1a8c5480981906ba6d4e305d7b';
const expectedSourceBytes = 14665;
const outputPath = 'lib/src/parser/inline/generated/unicode_emoji_regex.dart';

final Uri sourceUri = Uri.parse(
  'https://raw.githubusercontent.com/'
  'mathiasbynens/emoji-test-regex-pattern/$sourceRevision/'
  'dist/emoji-$unicodeVersion/javascript-u.txt',
);

/// Verifies both the size and Git blob SHA-1 of the pinned source bytes.
Future<void> validateSourceBytes(List<int> bytes) async {
  if (bytes.length != expectedSourceBytes) {
    throw FormatException(
      'Unexpected source size: ${bytes.length} bytes '
      '(expected $expectedSourceBytes for blob $sourceBlob).',
    );
  }

  final process = await Process.start('git', ['hash-object', '--stdin']);
  final output = process.stdout.transform(utf8.decoder).join();
  final errorOutput = process.stderr.transform(utf8.decoder).join();
  process.stdin.add(bytes);
  await process.stdin.close();

  final status = await process.exitCode;
  final actualBlob = (await output).trim();
  final error = (await errorOutput).trim();
  if (status != 0) {
    throw ProcessException(
      'git',
      const ['hash-object', '--stdin'],
      error,
      status,
    );
  }
  if (actualBlob != sourceBlob) {
    throw FormatException(
      'Unexpected source Git blob SHA-1: $actualBlob '
      '(expected $sourceBlob).',
    );
  }
}

Future<void> main() async {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run this tool from the repository root.');
    exitCode = 64;
    return;
  }

  final client = HttpClient();
  try {
    final request = await client.getUrl(sourceUri);
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'misskey_mfm_parser emoji regex updater',
    );
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      stderr.writeln(
        'Failed to download $sourceUri: HTTP ${response.statusCode}',
      );
      exitCode = 1;
      return;
    }

    final bytes = await response.fold<List<int>>(<int>[], (all, chunk) {
      all.addAll(chunk);
      return all;
    });
    try {
      await validateSourceBytes(bytes);
    } on FormatException catch (error) {
      stderr.writeln(error.message);
      exitCode = 1;
      return;
    }

    final pattern = utf8.decode(bytes).trim();
    if (pattern.isEmpty || pattern.contains('\n') || pattern.contains("'")) {
      stderr.writeln('Downloaded source is not the expected one-line pattern.');
      exitCode = 1;
      return;
    }

    final output =
        '''
// GENERATED CODE - DO NOT MODIFY BY HAND.
//
// Unicode Emoji version: $unicodeVersion
// Source: https://github.com/mathiasbynens/emoji-test-regex-pattern
// Revision: $sourceRevision
// Source blob: $sourceBlob
// License: MIT (see third_party/emoji-test-regex-pattern/LICENSE)
// Regenerate: dart run tool/update_unicode_emoji_regex.dart

/// A Unicode $unicodeVersion RGI emoji sequence regular expression.
const unicodeEmojiRegexPattern =
    r'$pattern';
''';

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(output);
    stdout.writeln('Updated $outputPath from $sourceUri');
  } finally {
    client.close(force: true);
  }
}
