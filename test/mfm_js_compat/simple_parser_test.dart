/// mfm.js 互換性テスト - SimpleParser
///
/// mfm.js/test/parser.tsのSimpleParserセクション（行8-66）をDartに移植
///
/// Source: https://github.com/misskey-dev/mfm.js/blob/develop/test/parser.ts
library;

import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('SimpleParser', () {
    final parser = MfmParser().buildSimple();

    group('text', () {
      // mfm.js/test/parser.ts:10-14
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse('abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'abc');
      });

      // mfm.js/test/parser.ts:16-20
      test('mfm-js互換テスト: ignore hashtag', () {
        // simpleParserではハッシュタグは無視される
        final result = parser.parse('abc#abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'abc#abc');
      });

      // mfm.js/test/parser.ts:22-26
      test('mfm-js互換テスト: keycap number sign', () {
        // #️⃣ はUnicode絵文字として認識される
        final result = parser.parse('abc#️⃣abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'abc');
        expect(nodes[1], isA<UnicodeEmojiNode>());
        expect((nodes[1] as UnicodeEmojiNode).emoji, '#️⃣');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, 'abc');
      });
    });

    group('emoji', () {
      // mfm.js/test/parser.ts:30-34
      test('mfm-js互換テスト: basic emojiCode', () {
        final result = parser.parse(':foo:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<EmojiCodeNode>());
        expect((nodes[0] as EmojiCodeNode).name, 'foo');
      });

      // mfm.js/test/parser.ts:36-40
      test('mfm-js互換テスト: between texts', () {
        // 英数字で挟まれたemojiCodeは無効
        final result = parser.parse('foo:bar:baz');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'foo:bar:baz');
      });

      // mfm.js/test/parser.ts:42-46
      test('mfm-js互換テスト: between texts 2', () {
        // 数字で挟まれたemojiCodeは無効
        final result = parser.parse('12:34:56');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '12:34:56');
      });

      // mfm.js/test/parser.ts:48-52
      test('mfm-js互換テスト: between texts 3', () {
        // 日本語で挟まれたemojiCodeは有効
        final result = parser.parse('あ:bar:い');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'あ');
        expect(nodes[1], isA<EmojiCodeNode>());
        expect((nodes[1] as EmojiCodeNode).name, 'bar');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, 'い');
      });

      // mfm.js/test/parser.ts:54-58
      test('mfm-js互換テスト: Ignore Variation Selector preceded by Unicode Emoji', () {
        // 異体字セレクタ(U+FE0F)単体はテキストとして扱う
        final result = parser.parse('\uFE0F');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '\uFE0F');
      });
    });

    // mfm.js/test/parser.ts:61-65
    group('disallow other syntaxes', () {
      test('mfm-js互換テスト: bold is ignored', () {
        final result = parser.parse('foo **bar** baz');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'foo **bar** baz');
      });
    });
  });
}
