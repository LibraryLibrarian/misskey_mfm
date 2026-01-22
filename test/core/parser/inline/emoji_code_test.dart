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

  // mfm-js準拠テスト（前後文字チェック）
  group('EmojiCodeParser（mfm-js準拠 - 前後文字チェック）', () {
    final parser = MfmParser().build();

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

    test('前が英数字、後が非英数字の場合は無効', () {
      // foo:bar: → TEXT('foo:bar:')
      final result = parser.parse('foo:bar:');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 前が英数字なのでマッチしない
      expect(nodes, [const TextNode('foo:bar:')]);
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
  });
}
