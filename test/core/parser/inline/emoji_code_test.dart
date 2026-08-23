import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/inline/emoji_code.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('EmojiCodeParser（カスタム絵文字）', () {
    final parser = EmojiCodeParser().build();

    test('プラス記号を含む絵文字名を解析できる', () {
      final result = parser.parse(':+1:');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const EmojiCodeNode('+1'));
    });

    test('数字のみの絵文字名を解析できる', () {
      final result = parser.parse(':100:');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const EmojiCodeNode('100'));
    });

    test('大文字を含む絵文字名を解析できる', () {
      final result = parser.parse(':ThinkingFace:');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const EmojiCodeNode('ThinkingFace'));
    });

    test('空の絵文字名（::）は解析失敗する', () {
      final result = parser.parse('::');
      expect(result is Failure, isTrue);
    });

    test('閉じコロンがない場合は解析失敗する', () {
      final result = parser.parse(':emoji');
      expect(result is Failure, isTrue);
    });

    test('不正な文字を含む絵文字名は部分的に解析される', () {
      // :emoji!:は:emojiまでマッチして!で止まる
      final result = parser.parse(':emoji!:');
      expect(result is Failure, isTrue);
    });

    test('スペースを含む絵文字名は解析失敗する', () {
      final result = parser.parse(':emoji name:');
      expect(result is Failure, isTrue);
    });

    test('非0位置で直前が英数字でも解析し、終了位置を返す', () {
      const input = 'abc:foo: tail';
      final result = parser.parseOn(const Context(input, 3));
      expect(result, isA<Success<MfmNode>>());
      expect((result as Success<MfmNode>).value, const EmojiCodeNode('foo'));
      expect(result.position, 8);
    });

    test('非0位置でも閉じcolon直後が英数字なら開始位置で失敗する', () {
      const input = 'abc:foo:x';
      final result = parser.parseOn(const Context(input, 3));
      expect(result, isA<Failure>());
      expect(result.position, 3);
    });

    test('大文字とplus・minus・underscoreを含む名前を解析できる', () {
      final result = parser.parse(':UPPER_+1-:');
      expect(result, isA<Success<MfmNode>>());
      expect(
        (result as Success<MfmNode>).value,
        const EmojiCodeNode('UPPER_+1-'),
      );
    });
  });

  group('EmojiCodeParser（フォールバック付き）', () {
    final parser = EmojiCodeParser().buildWithFallback();

    test('有効な絵文字を解析できる', () {
      final result = parser.parse(':emoji:');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const EmojiCodeNode('emoji'));
    });

    test('無効な場合はコロンをテキストとして返す', () {
      final result = parser.parse(':');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const TextNode(':'));
    });
  });

  group('MfmParser統合テスト（カスタム絵文字）', () {
    final parser = MfmParser().build();

    test('テキスト内のカスタム絵文字を解析できる', () {
      final result = parser.parse('Hello :wave: World');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('Hello '),
        const EmojiCodeNode('wave'),
        const TextNode(' World'),
      ]);
    });

    test('複数のカスタム絵文字を解析できる', () {
      final result = parser.parse(':hello::world:');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const EmojiCodeNode('hello'),
        const EmojiCodeNode('world'),
      ]);
    });

    test('太字内のカスタム絵文字を解析できる', () {
      final result = parser.parse('**:emoji:**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const BoldNode([EmojiCodeNode('emoji')]),
      ]);
    });

    test('無効なコロンはテキストとして扱われる', () {
      final result = parser.parse('Hello : World');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // コロンがテキストとして含まれる
      expect(nodes, [const TextNode('Hello : World')]);
    });
  });

  // mfm-js準拠テスト（開始前は制約なし、閉じcolon後だけ英数字を拒否）
  group('EmojiCodeParser（mfm-js準拠 - 後方文字チェック）', () {
    final parser = MfmParser().build();
    final simpleParser = MfmParser().buildSimple();

    test('英数字直後のemoji codeをfull parserで解析する', () {
      final result = parser.parse('abc:foo:');
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        TextNode('abc'),
        EmojiCodeNode('foo'),
      ]);
    });

    test('英数字直後のemoji codeをsimple parserでも解析する', () {
      final result = simpleParser.parse('hello:smile:');
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        TextNode('hello'),
        EmojiCodeNode('smile'),
      ]);
    });

    test('英数字に囲まれた絵文字コードは無効（foo:bar:baz）', () {
      // mfm-js: foo:bar:baz → TEXT('foo:bar:baz')
      final result = parser.parse('foo:bar:baz');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 全体がテキストとして扱われる
      expect(nodes, [const TextNode('foo:bar:baz')]);
    });

    test('数字に囲まれた絵文字コードは無効（12:34:56）', () {
      // mfm-js: 12:34:56 → TEXT('12:34:56')
      final result = parser.parse('12:34:56');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 全体がテキストとして扱われる（時刻形式）
      expect(nodes, [const TextNode('12:34:56')]);
    });

    test('非英数字（日本語）に囲まれた絵文字コードは有効（あ:bar:い）', () {
      // mfm-js: あ:bar:い → TEXT('あ'), EMOJI_CODE('bar'), TEXT('い')
      final result = parser.parse('あ:bar:い');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('あ'),
        const EmojiCodeNode('bar'),
        const TextNode('い'),
      ]);
    });

    test('行頭の絵文字コードは有効', () {
      // mfm-js: :foo: → EMOJI_CODE('foo')
      final result = parser.parse(':foo:');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [const EmojiCodeNode('foo')]);
    });

    test('行末の絵文字コードは有効', () {
      // mfm-js: text :foo: → TEXT('text '), EMOJI_CODE('foo')
      final result = parser.parse('text :foo:');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [const TextNode('text '), const EmojiCodeNode('foo')]);
    });

    test('スペースで区切られた絵文字コードは有効', () {
      // mfm-js: foo :bar: baz → TEXT('foo '), EMOJI_CODE('bar'), TEXT(' baz')
      final result = parser.parse('foo :bar: baz');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('foo '),
        const EmojiCodeNode('bar'),
        const TextNode(' baz'),
      ]);
    });

    test('前が英数字でも後が非英数字なら有効', () {
      // mfm-js: foo:bar: → TEXT('foo'), EMOJI_CODE('bar')
      final result = parser.parse('foo:bar:');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [const TextNode('foo'), const EmojiCodeNode('bar')]);
    });

    test('前が非英数字、後が英数字の場合は無効', () {
      // :bar:baz → TEXT(':bar:baz')
      final result = parser.parse(':bar:baz');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 後が英数字なのでマッチしない
      expect(nodes, [const TextNode(':bar:baz')]);
    });

    test('記号で区切られた絵文字コードは有効', () {
      // !:emoji:! → TEXT('!'), EMOJI_CODE('emoji'), TEXT('!')
      final result = parser.parse('!:emoji:!');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('!'),
        const EmojiCodeNode('emoji'),
        const TextNode('!'),
      ]);
    });

    test('改行で区切られた絵文字コードは有効', () {
      final result = parser.parse('text\n:emoji:\nmore');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('text\n'),
        const EmojiCodeNode('emoji'),
        const TextNode('\nmore'),
      ]);
    });

    test('URLのschemeとportはfull parserでURLのまま維持する', () {
      const input = 'https://example.com:8080/path';
      final result = parser.parse(input);
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        UrlNode(url: input),
      ]);
    });

    test('URLのschemeとportはsimple parserでTextのまま維持する', () {
      const input = 'https://example.com:8080/path';
      final result = simpleParser.parse(input);
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        TextNode(input),
      ]);
    });

    test('closing colonのない通常文はTextのまま維持する', () {
      const input = 'key:value and ratio 16:9';
      final result = parser.parse(input);
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        TextNode(input),
      ]);
    });
  });
}
