import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('MathInlineParser（インライン数式）', () {
    test(r'複雑な数式: \(x = {-b \pm \sqrt{b^2-4ac} \over 2a}\)', () {
      final m = MfmParser().build();
      final result = m.parse(r'\(x = {-b \pm \sqrt{b^2-4ac} \over 2a}\)');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<MathInlineNode>());
      final math = nodes[0] as MathInlineNode;
      expect(math.formula, r'x = {-b \pm \sqrt{b^2-4ac} \over 2a}');
    });

    test(r'テキスト内: 式は\(y = 2x\)です', () {
      final m = MfmParser().build();
      final result = m.parse(r'式は\(y = 2x\)です');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect((nodes[0] as TextNode).text, '式は');
      expect(nodes[1], isA<MathInlineNode>());
      expect((nodes[1] as MathInlineNode).formula, 'y = 2x');
      expect((nodes[2] as TextNode).text, 'です');
    });

    test(r'分数: \(\frac{1}{2}\)', () {
      final m = MfmParser().build();
      final result = m.parse(r'\(\frac{1}{2}\)');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<MathInlineNode>());
      final math = nodes[0] as MathInlineNode;
      expect(math.formula, r'\frac{1}{2}');
    });

    test('複数の数式: \\(a\\)と\\(b\\)', () {
      final m = MfmParser().build();
      final result = m.parse(r'\(a\)と\(b\)');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<MathInlineNode>());
      expect((nodes[0] as MathInlineNode).formula, 'a');
      expect((nodes[1] as TextNode).text, 'と');
      expect(nodes[2], isA<MathInlineNode>());
      expect((nodes[2] as MathInlineNode).formula, 'b');
    });
  });
}
