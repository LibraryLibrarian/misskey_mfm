/// mfm.js 互換性テスト - FullParser
///
/// mfm.js/test/parser.tsのFullParserセクション（行68-1540）をDartに移植
///
/// Source: https://github.com/misskey-dev/mfm.js/blob/develop/test/parser.ts
library;

import 'package:misskey_mfm/core/parser.dart';
import 'package:test/test.dart';

void main() {
  group('FullParser', () {
    // ignore: unused_local_variable
    final parser = MfmParser().build();

    // mfm.js:69-75
    group('text', () {});

    // mfm.js:77-183
    group('quote', () {});

    // mfm.js:185-239
    group('search', () {});

    // mfm.js:241-284
    group('code block', () {});

    // mfm.js:286-317
    group('mathBlock', () {});

    // mfm.js:319-340
    group('center', () {});

    // mfm.js:342-348
    group('emoji code', () {});

    // mfm.js:350-362
    group('unicode emoji', () {});

    // mfm.js:364-399
    group('big', () {});

    // mfm.js:402-438
    group('bold tag', () {});

    // mfm.js:440-476
    group('bold', () {});

    // mfm.js:478-514
    group('small', () {});

    // mfm.js:516-552
    group('italic tag', () {});

    // mfm.js:554-592
    group('italic alt 1', () {});

    // mfm.js:594-632
    group('italic alt 2', () {});

    // mfm.js:634-642
    group('strike tag', () {});

    // mfm.js:644-652
    group('strike', () {});

    // mfm.js:654-672
    group('inlineCode', () {});

    // mfm.js:674-680
    group('mathInline', () {});

    // mfm.js:682-796
    group('mention', () {});

    // mfm.js:798-928
    group('hashtag', () {});

    // mfm.js:930-1064
    group('url', () {});

    // mfm.js:1066-1228
    group('link', () {});

    // mfm.js:1230-1280
    group('fn', () {});

    // mfm.js:1282-1302
    group('plain', () {});

    // mfm.js:1304-1509
    group('nesting limit', () {});

    // mfm.js:1512-1540
    group('composite', () {});
  });
}
