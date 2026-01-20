import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('MathBlockParser（数式ブロック）', () {
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

  });
}
