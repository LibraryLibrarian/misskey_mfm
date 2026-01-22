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
      expect(nodes, [
        const MathInlineNode(r'x = {-b \pm \sqrt{b^2-4ac} \over 2a}'),
      ]);
    });

    test(r'テキスト内: 式は\(y = 2x\)です', () {
      final m = MfmParser().build();
      final result = m.parse(r'式は\(y = 2x\)です');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('式は'),
        const MathInlineNode('y = 2x'),
        const TextNode('です'),
      ]);
    });

    test(r'分数: \(\frac{1}{2}\)', () {
      final m = MfmParser().build();
      final result = m.parse(r'\(\frac{1}{2}\)');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [const MathInlineNode(r'\frac{1}{2}')]);
    });

    test('複数の数式: \\(a\\)と\\(b\\)', () {
      final m = MfmParser().build();
      final result = m.parse(r'\(a\)と\(b\)');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const MathInlineNode('a'),
        const TextNode('と'),
        const MathInlineNode('b'),
      ]);
    });
  });
}
