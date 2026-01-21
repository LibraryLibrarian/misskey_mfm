import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/inline/unicode_emoji.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('UnicodeEmojiParser（Unicode絵文字）', () {
    final parser = UnicodeEmojiParser().build();

    test('ハンドサインの絵文字を解析できる', () {
      final result = parser.parse('👍');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<UnicodeEmojiNode>());
      expect((node as UnicodeEmojiNode).emoji, '👍');
    });

    test('肌色修飾子付きの絵文字を解析できる', () {
      final result = parser.parse('👍🏻');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<UnicodeEmojiNode>());
      expect((node as UnicodeEmojiNode).emoji, '👍🏻');
    });

    test('ZWJ結合絵文字（家族）を解析できる', () {
      final result = parser.parse('👨‍👩‍👧‍👦');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<UnicodeEmojiNode>());
      expect((node as UnicodeEmojiNode).emoji, '👨‍👩‍👧‍👦');
    });

    test('国旗絵文字を解析できる', () {
      final result = parser.parse('🇯🇵');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<UnicodeEmojiNode>());
      expect((node as UnicodeEmojiNode).emoji, '🇯🇵');
    });

    test('ハート絵文字を解析できる', () {
      final result = parser.parse('❤️');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<UnicodeEmojiNode>());
    });

    test('複合絵文字（職業）を解析できる', () {
      final result = parser.parse('👨‍💻');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<UnicodeEmojiNode>());
      expect((node as UnicodeEmojiNode).emoji, '👨‍💻');
    });

    test('通常のテキストは解析失敗する', () {
      final result = parser.parse('hello');
      expect(result is Failure, isTrue);
    });

    test('数字は解析失敗する', () {
      final result = parser.parse('123');
      expect(result is Failure, isTrue);
    });
  });

  group('MfmParser統合テスト（Unicode絵文字）', () {
    final parser = MfmParser().build();
    test('テキスト内のUnicode絵文字を解析できる', () {
      final result = parser.parse('Hello 👋 World');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'Hello ');
      expect(nodes[1], isA<UnicodeEmojiNode>());
      expect((nodes[1] as UnicodeEmojiNode).emoji, '👋');
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, ' World');
    });

    test('複数のUnicode絵文字を解析できる', () {
      final result = parser.parse('😀😁😂');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<UnicodeEmojiNode>());
      expect(nodes[1], isA<UnicodeEmojiNode>());
      expect(nodes[2], isA<UnicodeEmojiNode>());
    });

    test('太字内のUnicode絵文字を解析できる', () {
      final result = parser.parse('**😀**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<BoldNode>());
      final bold = nodes[0] as BoldNode;
      expect(bold.children.length, 1);
      expect(bold.children[0], isA<UnicodeEmojiNode>());
    });

    test('カスタム絵文字とUnicode絵文字の混在を解析できる', () {
      final result = parser.parse(':wave: 👋');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<EmojiCodeNode>());
      expect((nodes[0] as EmojiCodeNode).name, 'wave');
      expect(nodes[1], isA<TextNode>());
      expect(nodes[2], isA<UnicodeEmojiNode>());
    });

    test('絵文字を含む文章全体を解析できる', () {
      final result = parser.parse('今日は良い天気ですね 🌞 :sunny:');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // テキスト + Unicode絵文字 + テキスト + カスタム絵文字
      expect(nodes.any((n) => n is UnicodeEmojiNode), isTrue);
      expect(nodes.any((n) => n is EmojiCodeNode), isTrue);
    });
  });
}
