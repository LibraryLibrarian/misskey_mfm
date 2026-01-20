import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('MathBlockParser（数式ブロック）', () {
    // mfm.js/test/parser.ts:287-293
    test(r'mfm-js互換テスト: 1行の数式ブロックを使用できる', () {
      final m = MfmParser().build();
      final result = m.parse(r'\[math1\]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<MathBlockNode>());
      final math = nodes[0] as MathBlockNode;
      expect(math.formula, 'math1');
    });

    test(r'複数行: \[\na = 2\n\]', () {
      final m = MfmParser().build();
      final result = m.parse('\\[\na = 2\n\\]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<MathBlockNode>());
      final math = nodes[0] as MathBlockNode;
      expect(math.formula, 'a = 2');
    });

    test(r'複雑な数式: \[x = {-b \pm \sqrt{b^2-4ac} \over 2a}\]', () {
      final m = MfmParser().build();
      final result = m.parse(r'\[x = {-b \pm \sqrt{b^2-4ac} \over 2a}\]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<MathBlockNode>());
      final math = nodes[0] as MathBlockNode;
      expect(math.formula, r'x = {-b \pm \sqrt{b^2-4ac} \over 2a}');
    });

    // mfm.js/test/parser.ts:294-302
    test('mfm-js互換テスト: ブロックの前後にあるテキストが正しく解釈される', () {
      final m = MfmParser().build();
      final result = m.parse('abc\n\\[math\\]\nxyz');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // abc\n, mathBlock, \nxyz の3つ
      expect(nodes.any((n) => n is MathBlockNode), isTrue);
    });

    // mfm.js/test/parser.ts:303-309
    test(r'mfm-js互換テスト: 行末以外に閉じタグがある場合はマッチしない', () {
      final m = MfmParser().build();
      final result = m.parse(r'\[aaa\]after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // MathBlockとしてパースされず、プレーンテキストとして扱われる
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, r'\[aaa\]after');
    });

    // mfm.js/test/parser.ts:310-316
    test(r'mfm-js互換テスト: 行頭以外に開始タグがある場合はマッチしない', () {
      final m = MfmParser().build();
      final result = m.parse(r'before\[aaa\]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // MathBlockとしてパースされず、プレーンテキストとして扱われる
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, r'before\[aaa\]');
    });
  });
}
