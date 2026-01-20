import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('CenterParser（中央寄せ: タグ）', () {
    // mfm.js/test/parser.ts:320-328
    test('mfm-js互換テスト: single text', () {
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

    // mfm.js/test/parser.ts:329-339
    test('mfm-js互換テスト: multiple text', () {
      final m = MfmParser().build();
      const input = 'before\n<center>\nabc\n123\n\npiyo\n</center>\nafter';
      final result = m.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);

      // TEXT('before')
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'before');

      // CENTER([TEXT('abc\n123\n\npiyo')])
      expect(nodes[1], isA<CenterNode>());
      final center = nodes[1] as CenterNode;
      expect(center.children.length, 1);
      expect(center.children[0], isA<TextNode>());
      expect((center.children[0] as TextNode).text, 'abc\n123\n\npiyo');

      // TEXT('after')
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, 'after');
    });
  });
}
