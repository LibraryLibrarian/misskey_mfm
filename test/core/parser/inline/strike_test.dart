import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/inline/strike.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('StrikeParser（~~形式）', () {
    final parser = StrikeParser().buildWithFallback();

    test('閉じタグがない場合はテキストとして扱う', () {
      final result = parser.parse('~~abc');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const TextNode('~~abc'));
    });

    test('空の打ち消し線タグを解析できる', () {
      final result = parser.parse('~~~~');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      // 空の場合はテキストとして扱われる（内容が必須）
      expect(node, const TextNode('~~~~'));
    });

    test('改行を含む場合はテキストとして扱う', () {
      final result = parser.parse('~~line1\nline2~~');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      // 改行を含む場合はパースに失敗してテキストになる
      expect(node, const TextNode('~~line1\nline2~~'));
    });

    test('単独の~~はテキストとして扱う', () {
      final result = parser.parse('~~');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const TextNode('~~'));
    });

    test('閉じタグがない場合の詳細テスト', () {
      final testCases = [
        ('~~abc', '~~abc'),
        ('~~abc def', '~~abc def'),
        ('~~', '~~'),
      ];

      for (final (input, expected) in testCases) {
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final node = (result as Success).value as MfmNode;
        expect(node, TextNode(expected));
      }
    });

    test('閉じタグが途中にある場合は解析失敗', () {
      // abc~~def のような場合は解析失敗（~~で始まらないため）
      final result = parser.parse('abc~~def');
      expect(result is Failure, isTrue);
    });
  });

  group('StrikeTagParser（<s>形式）', () {
    test('<s>タグ内で改行を含む場合も解析できる', () {
      final m = MfmParser().build();
      final result = m.parse('<s>line1\nline2</s>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const StrikeNode([TextNode('line1\nline2')]),
      ]);
    });

    test('<s>タグが閉じられていない場合はテキストとして扱う', () {
      final m = MfmParser().build();
      final result = m.parse('<s>abc');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 閉じタグがない場合は個別の文字としてパースされる
      expect(nodes, [const TextNode('<s>abc')]);
    });
  });

  group('Strike統合テスト（MfmParser経由）', () {
    test('~~形式の打ち消し線を解析できる', () {
      final m = MfmParser().build();
      final result = m.parse('~~strike~~');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const StrikeNode([TextNode('strike')]),
      ]);
    });

    test('テキストと打ち消し線の組み合わせ', () {
      final m = MfmParser().build();
      final result = m.parse('before ~~strike~~ after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('before '),
        const StrikeNode([TextNode('strike')]),
        const TextNode(' after'),
      ]);
    });

    test('打ち消し線内にボールドをネストできる', () {
      final m = MfmParser().build();
      final result = m.parse('<s>**bold**</s>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const StrikeNode([
          BoldNode([TextNode('bold')]),
        ]),
      ]);
    });

    test('ボールド内に打ち消し線をネストできる', () {
      final m = MfmParser().build();
      final result = m.parse('**~~strike~~**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const BoldNode([
          StrikeNode([TextNode('strike')]),
        ]),
      ]);
    });

    test('打ち消し線内にイタリックをネストできる', () {
      final m = MfmParser().build();
      final result = m.parse('~~<i>italic</i>~~');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const StrikeNode([
          ItalicNode([TextNode('italic')]),
        ]),
      ]);
    });

    test('複数の打ち消し線を連続で解析できる', () {
      final m = MfmParser().build();
      final result = m.parse('~~one~~ ~~two~~');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const StrikeNode([TextNode('one')]),
        const TextNode(' '),
        const StrikeNode([TextNode('two')]),
      ]);
    });

    test('打ち消し線内に絵文字コードを含められる', () {
      final m = MfmParser().build();
      final result = m.parse('<s>:emoji:</s>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const StrikeNode([EmojiCodeNode('emoji')]),
      ]);
    });
  });
}
