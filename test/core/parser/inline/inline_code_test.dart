import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('InlineCodeParser（インラインコード）', () {
    test('基本: `var x = 1;`', () {
      final m = MfmParser().build();
      final result = m.parse('AiScript: `#abc = 2`');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as TextNode).text, 'AiScript: ');
      expect(nodes[1], isA<InlineCodeNode>());
      expect((nodes[1] as InlineCodeNode).code, '#abc = 2');
    });

    test('改行は不可: 無効としてテキスト化', () {
      final m = MfmParser().build();
      final result = m.parse('`foo\nbar`');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect((nodes[0] as TextNode).text, '`foo\nbar`');
    });

    test('アキュートアクセントは不可: 無効としてテキスト化', () {
      final m = MfmParser().build();
      final result = m.parse('`foo´bar`');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect((nodes[0] as TextNode).text, '`foo´bar`');
    });
  });
}
