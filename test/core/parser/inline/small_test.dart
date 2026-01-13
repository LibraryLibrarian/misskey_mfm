import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('SmallParser（small タグ）', () {
    test('基本: <small>abc</small>', () {
      final m = MfmParser().build();
      final result = m.parse('<small>abc</small>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<SmallNode>());
      final small = nodes[0] as SmallNode;
      expect(small.children.length, 1);
      expect((small.children.first as TextNode).text, 'abc');
    });
  });
}
