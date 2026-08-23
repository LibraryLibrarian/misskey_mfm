import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/inline/unicode_emoji.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  const unicode17Emoji = <String, String>{
    'lime': '🍋‍🟩',
    'head shaking horizontally': '🙂‍↔️',
    'broken chain': '⛓️‍💥',
    'phoenix': '🐦‍🔥',
    'face with bags under eyes': '🫩',
    'leafless tree': '🪾',
    'fingerprint': '🫆',
  };

  group('UnicodeEmojiParser（Unicode絵文字）', () {
    final parser = UnicodeEmojiParser().build();

    for (final entry in unicode17Emoji.entries) {
      test('Unicode 17.0: ${entry.key}を1ノード分だけ解析できる', () {
        final result = parser.parse(entry.value);
        expect(result, isA<Success<MfmNode>>());
        expect(
          (result as Success<MfmNode>).value,
          UnicodeEmojiNode(entry.value),
        );
        expect(result.position, entry.value.length);
      });
    }

    test('ハンドサインの絵文字を解析できる', () {
      final result = parser.parse('👍');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const UnicodeEmojiNode('👍'));
    });

    test('肌色修飾子付きの絵文字を解析できる', () {
      final result = parser.parse('👍🏻');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const UnicodeEmojiNode('👍🏻'));
    });

    test('ZWJ結合絵文字（家族）を解析できる', () {
      final result = parser.parse('👨‍👩‍👧‍👦');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const UnicodeEmojiNode('👨‍👩‍👧‍👦'));
    });

    test('国旗絵文字を解析できる', () {
      final result = parser.parse('🇯🇵');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const UnicodeEmojiNode('🇯🇵'));
    });

    test('ハート絵文字を解析できる', () {
      final result = parser.parse('❤️');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const UnicodeEmojiNode('❤️'));
    });

    test('複合絵文字（職業）を解析できる', () {
      final result = parser.parse('👨‍💻');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const UnicodeEmojiNode('👨‍💻'));
    });

    test('keycap sequenceを1ノード分だけ解析できる', () {
      const emoji = '#️⃣';
      final result = parser.parse(emoji);
      expect(result, isA<Success<MfmNode>>());
      expect((result as Success<MfmNode>).value, const UnicodeEmojiNode(emoji));
      expect(result.position, emoji.length);
    });

    test('subdivision flag tag sequenceを1ノード分だけ解析できる', () {
      const emoji =
          '\u{1F3F4}\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}';
      final result = parser.parse(emoji);
      expect(result, isA<Success<MfmNode>>());
      expect((result as Success<MfmNode>).value, const UnicodeEmojiNode(emoji));
      expect(result.position, emoji.length);
    });

    test('非0位置から最長のZWJ sequenceに一致し終了位置を返す', () {
      const emoji = '🐦‍🔥';
      const input = 'a${emoji}z';
      final result = parser.parseOn(const Context(input, 1));
      expect(result, isA<Success<MfmNode>>());
      expect(
        (result as Success<MfmNode>).value,
        const UnicodeEmojiNode(emoji),
      );
      expect(result.position, 1 + emoji.length);
    });

    test('非RGIのZWJ列は全体を1絵文字として消費しない', () {
      const base = '🍋';
      const input = '$base\u200D🟥';
      final result = parser.parse(input);
      expect(result, isA<Success<MfmNode>>());
      expect((result as Success<MfmNode>).value, const UnicodeEmojiNode(base));
      expect(result.position, base.length);
    });

    test('単独variation selectorは解析失敗する', () {
      final result = parser.parse('\uFE0F');
      expect(result, isA<Failure>());
    });

    test('単独regional indicatorは解析失敗する', () {
      final result = parser.parse('🇯');
      expect(result, isA<Failure>());
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
    final simpleParser = MfmParser().buildSimple();

    for (final entry in unicode17Emoji.entries) {
      test('full parserがUnicode 17.0 ${entry.key}を1ノードにする', () {
        final result = parser.parse(entry.value);
        expect(result, isA<Success<List<MfmNode>>>());
        expect(
          (result as Success<List<MfmNode>>).value,
          [UnicodeEmojiNode(entry.value)],
        );
      });

      test('simple parserがUnicode 17.0 ${entry.key}を1ノードにする', () {
        final result = simpleParser.parse(entry.value);
        expect(result, isA<Success<List<MfmNode>>>());
        expect(
          (result as Success<List<MfmNode>>).value,
          [UnicodeEmojiNode(entry.value)],
        );
      });
    }
    test('テキスト内のUnicode絵文字を解析できる', () {
      final result = parser.parse('Hello 👋 World');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('Hello '),
        const UnicodeEmojiNode('👋'),
        const TextNode(' World'),
      ]);
    });

    test('複数のUnicode絵文字を解析できる', () {
      final result = parser.parse('😀😁😂');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const UnicodeEmojiNode('😀'),
        const UnicodeEmojiNode('😁'),
        const UnicodeEmojiNode('😂'),
      ]);
    });

    test('隣接するUnicode 17.0絵文字を別々のノードにする', () {
      final result = parser.parse('🍋‍🟩🫩🫆');
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        UnicodeEmojiNode('🍋‍🟩'),
        UnicodeEmojiNode('🫩'),
        UnicodeEmojiNode('🫆'),
      ]);
    });

    test('テキストに隣接するUnicode 17.0絵文字を分離する', () {
      final result = parser.parse('a🍋‍🟩b🫩c');
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        TextNode('a'),
        UnicodeEmojiNode('🍋‍🟩'),
        TextNode('b'),
        UnicodeEmojiNode('🫩'),
        TextNode('c'),
      ]);
    });

    test('旧来のRGI sequenceと単独variation selectorの扱いを維持する', () {
      const subdivisionFlag =
          '\u{1F3F4}\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}';
      final result = parser.parse(
        '👨‍👩‍👧‍👦 🇯🇵 👍🏻 #️⃣ $subdivisionFlag \uFE0F',
      );
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        UnicodeEmojiNode('👨‍👩‍👧‍👦'),
        TextNode(' '),
        UnicodeEmojiNode('🇯🇵'),
        TextNode(' '),
        UnicodeEmojiNode('👍🏻'),
        TextNode(' '),
        UnicodeEmojiNode('#️⃣'),
        TextNode(' '),
        UnicodeEmojiNode(subdivisionFlag),
        TextNode(' \uFE0F'),
      ]);
    });

    test('非RGIのZWJ列は1つのUnicodeEmojiNodeにしない', () {
      final result = parser.parse('🍋\u200D🟥');
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        UnicodeEmojiNode('🍋'),
        TextNode('\u200D'),
        UnicodeEmojiNode('🟥'),
      ]);
    });

    test('太字内のUnicode絵文字を解析できる', () {
      final result = parser.parse('**😀**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const BoldNode([UnicodeEmojiNode('😀')]),
      ]);
    });

    test('カスタム絵文字とUnicode絵文字の混在を解析できる', () {
      final result = parser.parse(':wave: 👋');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const EmojiCodeNode('wave'),
        const TextNode(' '),
        const UnicodeEmojiNode('👋'),
      ]);
    });

    test('絵文字を含む文章全体を解析できる', () {
      final result = parser.parse('今日は良い天気ですね 🌞 :sunny:');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('今日は良い天気ですね '),
        const UnicodeEmojiNode('🌞'),
        const TextNode(' '),
        const EmojiCodeNode('sunny'),
      ]);
    });
  });
}
