import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('InlineCodeParser（インラインコード）', () {
    // mfm.js/test/parser.ts:655-659
    test('mfm-js互換テスト: basic', () {
      final m = MfmParser().build();
      final result = m.parse('AiScript: `#abc = 2`');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as TextNode).text, 'AiScript: ');
      expect(nodes[1], isA<InlineCodeNode>());
      expect((nodes[1] as InlineCodeNode).code, '#abc = 2');
    });

    // mfm.js/test/parser.ts:661-665
    test('mfm-js互換テスト: disallow line break', () {
      final m = MfmParser().build();
      final result = m.parse('`foo\nbar`');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect((nodes[0] as TextNode).text, '`foo\nbar`');
    });

    // mfm.js/test/parser.ts:667-671
    test('mfm-js互換テスト: disallow ´', () {
      final m = MfmParser().build();
      final result = m.parse('`foo´bar`');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect((nodes[0] as TextNode).text, '`foo´bar`');
    });
  });
}
