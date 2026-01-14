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

  group('QuoteParser（引用: インライン構文対応）', () {
    test('引用内のbold: "> **太字**"', () {
      final m = MfmParser().build();
      final result = m.parse('> **太字**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<QuoteNode>());
      final quote = nodes[0] as QuoteNode;
      expect(quote.children.length, 1);
      expect(quote.children[0], isA<BoldNode>());
      final bold = quote.children[0] as BoldNode;
      expect((bold.children[0] as TextNode).text, '太字');
    });

    test('引用内のitalic: "> *斜体*"', () {
      final m = MfmParser().build();
      final result = m.parse('> *斜体*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<QuoteNode>());
      final quote = nodes[0] as QuoteNode;
      expect(quote.children.length, 1);
      expect(quote.children[0], isA<ItalicNode>());
    });

    test('引用内の複合: "> **太字**と*斜体*"', () {
      final m = MfmParser().build();
      final result = m.parse('> **太字**と*斜体*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<QuoteNode>());
      final quote = nodes[0] as QuoteNode;
      // [BoldNode, TextNode("と"), ItalicNode] の3要素
      expect(quote.children.length, 3);
      expect(quote.children[0], isA<BoldNode>());
      expect(quote.children[1], isA<TextNode>());
      expect(quote.children[2], isA<ItalicNode>());
    });

    test('引用内のインラインコード: "> `code`"', () {
      final m = MfmParser().build();
      final result = m.parse('> `code`');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<QuoteNode>());
      final quote = nodes[0] as QuoteNode;
      expect(quote.children.length, 1);
      expect(quote.children[0], isA<InlineCodeNode>());
      expect((quote.children[0] as InlineCodeNode).code, 'code');
    });

    test('複数行引用内のインライン: "> **1行目**\\n> *2行目*"', () {
      final m = MfmParser().build();
      final result = m.parse('> **1行目**\n> *2行目*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<QuoteNode>());
      final quote = nodes[0] as QuoteNode;
      // [BoldNode, TextNode("\n"), ItalicNode] の3要素
      expect(quote.children.length, 3);
      expect(quote.children[0], isA<BoldNode>());
      expect((quote.children[1] as TextNode).text, '\n');
      expect(quote.children[2], isA<ItalicNode>());
    });
  });

  group('QuoteParser（スペースなし引用）', () {
    test('スペースなし: ">abc"', () {
      final m = MfmParser().build();
      final result = m.parse('>abc');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<QuoteNode>());
      final quote = nodes[0] as QuoteNode;
      expect(quote.children.length, 1);
      expect((quote.children.first as TextNode).text, 'abc');
    });
  });
}
