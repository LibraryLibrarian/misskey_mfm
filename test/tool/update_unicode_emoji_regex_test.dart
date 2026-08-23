import 'dart:convert';

import 'package:misskey_mfm_parser/src/parser/inline/generated/unicode_emoji_regex.dart';
import 'package:test/test.dart';

import '../../tool/update_unicode_emoji_regex.dart';

void main() {
  group('Unicode emoji regex source integrity', () {
    final sourceBytes = utf8.encode(unicodeEmojiRegexPattern);

    test('accepts the pinned Unicode 17 source blob', () async {
      expect(sourceBytes.length, expectedSourceBytes);
      await expectLater(validateSourceBytes(sourceBytes), completes);
    });

    test('rejects a same-length one-byte modification', () async {
      final modified = List<int>.of(sourceBytes);
      modified[0] ^= 1;

      await expectLater(
        validateSourceBytes(modified),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Git blob SHA-1'),
          ),
        ),
      );
    });
  });
}
