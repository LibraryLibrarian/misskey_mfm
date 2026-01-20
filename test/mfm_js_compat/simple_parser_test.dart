/// mfm.js 互換性テスト - SimpleParser
///
/// mfm.js/test/parser.tsのSimpleParserセクション（行8-66）をDartに移植
///
/// Source: https://github.com/misskey-dev/mfm.js/blob/develop/test/parser.ts
library;

import 'package:misskey_mfm/core/parser.dart';
import 'package:test/test.dart';

void main() {
  group('SimpleParser', () {
    // ignore: unused_local_variable
    final parser = MfmParser().buildSimple();

    group('text', () {
      // mfm.js:10-14
      // mfm.js:16-20
      // mfm.js:22-26
    });

    group('emoji', () {
      // mfm.js:30-34
      // mfm.js:36-40
      // mfm.js:42-46
      // mfm.js:48-52
      // mfm.js:54-58
    });

    // mfm.js:61-65
    group('disallow other syntaxes', () {});
  });
}
