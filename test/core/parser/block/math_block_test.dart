import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('MathBlockParser（数式ブロック）', () {
    test(r'複数行: \[\na = 2\n\]', () {
      final m = MfmParser().build();
      final result = m.parse('\\[\na = 2\n\\]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [const MathBlockNode('a = 2')]);
    });

    test(r'複雑な数式: \[x = {-b \pm \sqrt{b^2-4ac} \over 2a}\]', () {
      final m = MfmParser().build();
      final result = m.parse(r'\[x = {-b \pm \sqrt{b^2-4ac} \over 2a}\]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(
        nodes,
        [const MathBlockNode(r'x = {-b \pm \sqrt{b^2-4ac} \over 2a}')],
      );
    });
  });
}
