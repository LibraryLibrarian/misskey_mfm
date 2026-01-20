import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('QuoteParser（引用: 1行）', () {
    // mfm.js/test/parser.ts:78-86
    test('mfm-js互換テスト: 1行の引用ブロックを使用できる', () {
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
    // mfm.js/test/parser.ts:87-98
    test('mfm-js互換テスト: 複数行の引用ブロックを使用できる', () {
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

  group('QuoteParser（ブロックネスト）', () {
    // mfm.js/test/parser.ts:99-113
    test('mfm-js互換テスト: 引用ブロックはブロックをネストできる', () {
      const input = '> <center>\n> a\n> </center>';
      final m = MfmParser().build();
      final result = m.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<QuoteNode>());
      final quote = nodes[0] as QuoteNode;
      expect(quote.children.length, 1);
      expect(quote.children[0], isA<CenterNode>());
      final center = quote.children[0] as CenterNode;
      expect(center.children.length, 1);
      expect(center.children[0], isA<TextNode>());
      // mfm-js期待値: 改行なし
      expect((center.children[0] as TextNode).text, 'a');
    });

    // mfm.js/test/parser.ts:114-129
    test('mfm-js互換テスト: 引用ブロックはインライン構文を含んだブロックをネストできる', () {
      const input = '> <center>\n> I\'m @ai, An bot of misskey!\n> </center>';
      final m = MfmParser().build();
      final result = m.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<QuoteNode>());
      final quote = nodes[0] as QuoteNode;
      expect(quote.children.length, 1);
      expect(quote.children[0], isA<CenterNode>());
      final center = quote.children[0] as CenterNode;
      expect(center.children.length, 3);
      expect(center.children[0], isA<TextNode>());
      // mfm-js期待値: 先頭に改行なし
      expect((center.children[0] as TextNode).text, "I'm ");
      expect(center.children[1], isA<MentionNode>());
      final mention = center.children[1] as MentionNode;
      expect(mention.username, 'ai');
      expect(mention.host, isNull);
      expect(mention.acct, '@ai');
      expect(center.children[2], isA<TextNode>());
      // mfm-js期待値: 末尾に改行なし
      expect((center.children[2] as TextNode).text, ', An bot of misskey!');
    });
  });

  group('QuoteParser（空行処理）', () {
    // mfm.js/test/parser.ts:131-143
    test('mfm-js互換テスト: 複数行の引用ブロックでは空行を含めることができる', () {
      const input = '> abc\n>\n> 123';
      final m = MfmParser().build();
      final result = m.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<QuoteNode>());
      final quote = nodes[0] as QuoteNode;
      expect(quote.children.length, 1);
      expect(quote.children[0], isA<TextNode>());
      expect((quote.children[0] as TextNode).text, 'abc\n\n123');
    });

    // mfm.js/test/parser.ts:144-150
    test('mfm-js互換テスト: 1行の引用ブロックを空行にはできない', () {
      // QuoteNodeではなくTextNodeになる
      const input = '> ';
      final m = MfmParser().build();
      final result = m.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, '> ');
    });

    // mfm.js/test/parser.ts:151-164
    test('mfm-js互換テスト: 引用ブロックの後ろの空行は無視される', () {
      const input = '> foo\n> bar\n\nhoge';
      final m = MfmParser().build();
      final result = m.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect(nodes[0], isA<QuoteNode>());
      final quote = nodes[0] as QuoteNode;
      expect(quote.children.length, 1);
      expect((quote.children[0] as TextNode).text, 'foo\nbar');
      expect(nodes[1], isA<TextNode>());
      // mfm-js期待値: 空行が除去されて'hoge'のみ
      expect((nodes[1] as TextNode).text, 'hoge');
    });

    // mfm.js/test/parser.ts:165-182
    test('mfm-js互換テスト: 2つの引用行の間に空行がある場合は2つの引用ブロックが生成される', () {
      const input = '> foo\n\n> bar\n\nhoge';
      final m = MfmParser().build();
      final result = m.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // mfm-js期待値: 3つのノード（QuoteNode, QuoteNode, TextNode）
      expect(nodes.length, 3);
      expect(nodes[0], isA<QuoteNode>());
      final quote1 = nodes[0] as QuoteNode;
      expect(quote1.children.length, 1);
      expect((quote1.children[0] as TextNode).text, 'foo');
      expect(nodes[1], isA<QuoteNode>());
      final quote2 = nodes[1] as QuoteNode;
      expect(quote2.children.length, 1);
      expect((quote2.children[0] as TextNode).text, 'bar');
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, 'hoge');
    });
  });
}
