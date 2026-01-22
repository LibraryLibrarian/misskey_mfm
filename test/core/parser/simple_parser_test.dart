import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
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
        expect(nodes, [const UnicodeEmojiNode('😀')]);
      });

      test('unicode emoji with text', () {
        final result = parser.parse('今起きた😇');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('今起きた'), const UnicodeEmojiNode('😇')]);
      });
    });

    group('disallow other syntaxes', () {
      test('italic is ignored', () {
        final result = parser.parse('foo *bar* baz');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('foo *bar* baz')]);
      });

      test('mention is ignored', () {
        final result = parser.parse('Hello @user');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('Hello @user')]);
      });

      test('url is ignored', () {
        final result = parser.parse('Visit https://example.com');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('Visit https://example.com')]);
      });

      test('link is ignored', () {
        final result = parser.parse('[text](https://example.com)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('[text](https://example.com)')]);
      });

      test('fn is ignored', () {
        final result = parser.parse(r'$[shake text]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode(r'$[shake text]')]);
      });

      test('strike is ignored', () {
        final result = parser.parse('foo ~~bar~~ baz');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('foo ~~bar~~ baz')]);
      });

      test('inline code is ignored', () {
        final result = parser.parse('foo `code` baz');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('foo `code` baz')]);
      });
    });

    group('plain tag', () {
      test('plain tag is supported', () {
        // plainタグはsimpleParserでもサポート（emojiCodeを内部でパースしないため）
        final result = parser.parse('<plain>:emoji:</plain>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // plain内部はそのままテキストとして保持
        expect(nodes, [
          const PlainNode([TextNode(':emoji:')]),
        ]);
      });
    });

    group('combined', () {
      test('text and emoji combined', () {
        final result = parser.parse('Hello :wave: World 😀');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('Hello '),
          const EmojiCodeNode('wave'),
          const TextNode(' World '),
          const UnicodeEmojiNode('😀'),
        ]);
      });

      test('multiple emoji codes', () {
        final result = parser.parse(':a::b::c:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const EmojiCodeNode('a'),
          const EmojiCodeNode('b'),
          const EmojiCodeNode('c'),
        ]);
      });

      test('multiple unicode emojis', () {
        final result = parser.parse('😀😁😂');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const UnicodeEmojiNode('😀'),
          const UnicodeEmojiNode('😁'),
          const UnicodeEmojiNode('😂'),
        ]);
      });
    });
  });
}
