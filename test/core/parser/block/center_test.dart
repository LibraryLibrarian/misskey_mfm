import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('CenterParser（中央寄せ: タグ）', () {
    test('基本: <center>abc</center>', () {
      final m = MfmParser().build();
      final result = m.parse('<center>abc</center>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<CenterNode>());
      final center = nodes[0] as CenterNode;
      expect(center.children.length, 1);
      expect((center.children.first as TextNode).text, 'abc');
    });
  });
}
