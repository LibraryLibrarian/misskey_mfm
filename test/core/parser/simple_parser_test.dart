import 'package:misskey_mfm_parser/core/ast.dart';
import 'package:misskey_mfm_parser/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('SimpleParser', () {
    final parser = MfmParser().buildSimple();

    group('emoji', () {
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
    });

    group('disallow other syntaxes', () {
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
