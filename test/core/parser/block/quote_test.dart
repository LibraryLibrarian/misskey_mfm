import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('QuoteParser（引用: 1行）', () {
    test('基本: "> abc"', () {
      final m = MfmParser().build();
      final result = m.parse('> abc');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<QuoteNode>());
      final quote = nodes[0] as QuoteNode;
      expect(quote.children.length, 1);
      expect((quote.children.first as TextNode).text, 'abc');
    });
  });

  group('QuoteParser（引用: 複数行）', () {
    test('基本: 連続する引用行', () {
      const input = '> これは\n> 複数行の\n> テスト';
      final m = MfmParser().build();
      final result = m.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<QuoteNode>());
      final quote = nodes[0] as QuoteNode;
      expect(quote.children.length, 1);
      expect((quote.children.first as TextNode).text, 'これは\n複数行の\nテスト');
    });
  });
}
