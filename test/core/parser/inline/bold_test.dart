import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/inline/bold.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('BoldParser（太字構文）', () {
    final parser = BoldParser().buildWithFallback();

    test('太字内に太字をネストできる（最も近い閉じタグを優先）', () {
      final result = parser.parse('**a **b** c**');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const BoldNode([TextNode('a ')]));
    });

    test('閉じタグがない場合はテキストとして扱う', () {
      final result = parser.parse('**abc');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      // **で始まるが閉じタグがない場合は、**以降の内容も含めてテキストとして返される
      expect(node, const TextNode('**abc'));
    });

    test('空の太字タグを解析できる', () {
      final result = parser.parse('****');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const BoldNode([]));
    });

    test('複数の太字タグを連続で解析できる', () {
      final result = parser.parse('**bold1****bold2**');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const BoldNode([TextNode('bold1')]));
    });

    test('単独の**はテキストとして扱う', () {
      final result = parser.parse('**');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const TextNode('**'));
    });

    test('閉じタグがない場合の詳細テスト', () {
      // **で始まるが閉じタグがない場合は、**以降の内容も含めてテキストとして返される
      final testCases = [
        ('**abc', '**abc'),
        ('**abc def', '**abc def'),
        ('**', '**'),
      ];

      for (final (input, expected) in testCases) {
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final node = (result as Success).value as MfmNode;
        expect(node, TextNode(expected));
      }
    });

    test('閉じタグが途中にある場合は適切に処理される', () {
      // abc**def のような場合は解析失敗（**で始まらないため）
      final result = parser.parse('abc**def');
      expect(result is Failure, isTrue);
    });
  });

  group('BoldTagParser（太字タグ <b>…</b>）', () {
    test('<b>abc*123*abc</b> の中のitalic構文はテキストとして扱われる', () {
      final m = MfmParser().build();
      final result = m.parse('<b>abc*123*abc</b>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const BoldNode([TextNode('abc*123*abc')]),
      ]);
    });
  });

  group('BoldUnderParser（太字アンダースコア構文 __...__）', () {
    final parser = BoldParser().buildUnder();

    test('基本的なboldUnder構文を解析できる', () {
      final result = parser.parse('__bold__');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const BoldNode([TextNode('bold')]));
    });

    test('英数字とスペースを含むboldUnder構文を解析できる', () {
      final result = parser.parse('__hello world 123__');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const BoldNode([TextNode('hello world 123')]));
    });

    test('タブ文字を含むboldUnder構文を解析できる', () {
      final result = parser.parse('__hello\tworld__');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const BoldNode([TextNode('hello\tworld')]));
    });

    test('全角スペースを含むboldUnder構文を解析できる', () {
      final result = parser.parse('__hello\u3000world__');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const BoldNode([TextNode('hello\u3000world')]));
    });

    test('閉じタグがない場合は解析失敗', () {
      final result = parser.parse('__abc');
      expect(result is Failure, isTrue);
    });

    test('空のboldUnder構文は解析失敗', () {
      // 内容が空の場合（____）はマッチしない
      final result = parser.parse('____');
      expect(result is Failure, isTrue);
    });

    test('許可されていない文字を含む場合は解析失敗', () {
      // 改行は許可されていない
      final result = parser.parse('__hello\nworld__');
      expect(result is Failure, isTrue);
    });

    test('日本語を含む場合は解析失敗', () {
      // 英数字のみ許可（日本語は許可されない）
      final result = parser.parse('__こんにちは__');
      expect(result is Failure, isTrue);
    });
  });

  group('BoldUnder統合テスト（MfmParser経由）', () {
    final mfmParser = MfmParser().build();

    test('基本的なboldUnder構文を解析できる', () {
      final result = mfmParser.parse('__abc__');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const BoldNode([TextNode('abc')]),
      ]);
    });

    test('テキストの前後にboldUnder構文がある場合', () {
      final result = mfmParser.parse('before __abc__ after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('before '),
        const BoldNode([TextNode('abc')]),
        const TextNode(' after'),
      ]);
    });

    test('boldUnderとitalicUnderが正しく区別される', () {
      // __ は boldUnder として解析されるべき
      final boldResult = mfmParser.parse('__abc__');
      expect(boldResult is Success, isTrue);
      final boldNodes = (boldResult as Success).value as List<MfmNode>;
      expect(boldNodes, [
        const BoldNode([TextNode('abc')]),
      ]);

      // _ は italic として解析されるべき
      final italicResult = mfmParser.parse('_abc_');
      expect(italicResult is Success, isTrue);
      final italicNodes = (italicResult as Success).value as List<MfmNode>;
      expect(italicNodes, [
        const ItalicNode([TextNode('abc')]),
      ]);
    });

    test('boldUnderは再帰パースを行わない', () {
      // __ 内の ** はテキストとして扱われる
      // mfm-js仕様: boldUnderは再帰パースなし
      final result = mfmParser.parse('__abc def__');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const BoldNode([TextNode('abc def')]),
      ]);
    });
  });
}
