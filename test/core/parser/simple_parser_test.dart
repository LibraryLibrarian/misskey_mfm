import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('SimpleParser', () {
    final parser = MfmParser().buildSimple();

    group('text', () {
      test('basic', () {
        final result = parser.parse('abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'abc');
      });

      test('ignore hashtag', () {
        // mfm-js仕様: simpleParserではハッシュタグは無視される
        final result = parser.parse('abc#abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'abc#abc');
      });

      test('keycap number sign', () {
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
      test('basic emojiCode', () {
        final result = parser.parse(':foo:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<EmojiCodeNode>());
        expect((nodes[0] as EmojiCodeNode).name, 'foo');
      });

      test('between texts', () {
        // mfm-js仕様: 英数字で挟まれたemojiCodeは無効
        final result = parser.parse('foo:bar:baz');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'foo:bar:baz');
      });

      test('between texts 2', () {
        // mfm-js仕様: 数字で挟まれたemojiCodeは無効
        final result = parser.parse('12:34:56');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '12:34:56');
      });

      test('between texts 3', () {
        // mfm-js仕様: 日本語で挟まれたemojiCodeは有効
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

      test('unicode emoji basic', () {
        final result = parser.parse('😀');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<UnicodeEmojiNode>());
        expect((nodes[0] as UnicodeEmojiNode).emoji, '😀');
      });

      test('unicode emoji with text', () {
        final result = parser.parse('今起きた😇');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 2);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '今起きた');
        expect(nodes[1], isA<UnicodeEmojiNode>());
        expect((nodes[1] as UnicodeEmojiNode).emoji, '😇');
      });

      test('Ignore Variation Selector preceded by Unicode Emoji', () {
        // mfm-js仕様: 異体字セレクタ(U+FE0F)単体はテキストとして扱う
        final result = parser.parse('\uFE0F');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '\uFE0F');
      });
    });

    group('disallow other syntaxes', () {
      test('bold is ignored', () {
        final result = parser.parse('foo **bar** baz');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'foo **bar** baz');
      });

      test('italic is ignored', () {
        final result = parser.parse('foo *bar* baz');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'foo *bar* baz');
      });

      test('mention is ignored', () {
        final result = parser.parse('Hello @user');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'Hello @user');
      });

      test('url is ignored', () {
        final result = parser.parse('Visit https://example.com');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'Visit https://example.com');
      });

      test('link is ignored', () {
        final result = parser.parse('[text](https://example.com)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '[text](https://example.com)');
      });

      test('fn is ignored', () {
        final result = parser.parse(r'$[shake text]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, r'$[shake text]');
      });

      test('strike is ignored', () {
        final result = parser.parse('foo ~~bar~~ baz');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'foo ~~bar~~ baz');
      });

      test('inline code is ignored', () {
        final result = parser.parse('foo `code` baz');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'foo `code` baz');
      });
    });

    group('plain tag', () {
      test('plain tag is supported', () {
        // plainタグはsimpleParserでもサポート（emojiCodeを内部でパースしないため）
        final result = parser.parse('<plain>:emoji:</plain>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<PlainNode>());
        // plain内部はそのままテキストとして保持
        final plainNode = nodes[0] as PlainNode;
        expect(plainNode.children.length, 1);
        expect(plainNode.children[0], isA<TextNode>());
        expect((plainNode.children[0] as TextNode).text, ':emoji:');
      });
    });

    group('combined', () {
      test('text and emoji combined', () {
        final result = parser.parse('Hello :wave: World 😀');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 4);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'Hello ');
        expect(nodes[1], isA<EmojiCodeNode>());
        expect((nodes[1] as EmojiCodeNode).name, 'wave');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, ' World ');
        expect(nodes[3], isA<UnicodeEmojiNode>());
        expect((nodes[3] as UnicodeEmojiNode).emoji, '😀');
      });

      test('multiple emoji codes', () {
        final result = parser.parse(':a::b::c:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes.every((n) => n is EmojiCodeNode), isTrue);
      });

      test('multiple unicode emojis', () {
        final result = parser.parse('😀😁😂');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes.every((n) => n is UnicodeEmojiNode), isTrue);
      });
    });
  });
}
