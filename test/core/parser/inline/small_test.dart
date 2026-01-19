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

    // mfm.js/test/parser.ts:488-499
    test('内容にはインライン構文を利用できる: <small>abc**123**abc</small>', () {
      final m = MfmParser().build();
      final result = m.parse('<small>abc**123**abc</small>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<SmallNode>());
      final small = nodes[0] as SmallNode;
      expect(small.children.length, 3);
      expect((small.children[0] as TextNode).text, 'abc');
      expect(small.children[1], isA<BoldNode>());
      final bold = small.children[1] as BoldNode;
      expect(bold.children.length, 1);
      expect((bold.children.first as TextNode).text, '123');
      expect((small.children[2] as TextNode).text, 'abc');
    });

    // mfm.js/test/parser.ts:501-513
    test('内容は改行できる: <small>abc\\n**123**\\nabc</small>', () {
      final m = MfmParser().build();
      final result = m.parse('<small>abc\n**123**\nabc</small>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<SmallNode>());
      final small = nodes[0] as SmallNode;
      expect(small.children.length, 3);
      expect((small.children[0] as TextNode).text, 'abc\n');
      expect(small.children[1], isA<BoldNode>());
      final bold = small.children[1] as BoldNode;
      expect(bold.children.length, 1);
      expect((bold.children.first as TextNode).text, '123');
      expect((small.children[2] as TextNode).text, '\nabc');
    });
  });
}
