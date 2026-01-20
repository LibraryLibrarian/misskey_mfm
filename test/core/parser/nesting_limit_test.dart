import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

/// mfm-js互換: nesting limit テスト
///
/// nestLimitオプションによるネスト深度制限テスト
/// パーサーのセキュリティと安定性に関わるテスト群
void main() {
  group('nesting limit', () {
    group('quote', () {
      // mfm.js/test/parser.ts:1306-1315
      test('mfm-js互換テスト: basic', () {
        // >>> abc → 2段階目まではネスト、3段階目(> abc)はテキスト
        final parser = MfmParser().build(nestLimit: 2);
        final result = parser.parse('>>> abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<QuoteNode>());
        final quote1 = nodes[0] as QuoteNode;
        expect(quote1.children.length, 1);
        expect(quote1.children[0], isA<QuoteNode>());
        final quote2 = quote1.children[0] as QuoteNode;
        expect(quote2.children.length, 1);
        expect(quote2.children[0], isA<TextNode>());
        expect((quote2.children[0] as TextNode).text, '> abc');
      });

      // mfm.js/test/parser.ts:1318-1327
      test('mfm-js互換テスト: basic 2', () {
        // >> **abc** → 2段階目までネスト、**abc**はテキスト
        final parser = MfmParser().build(nestLimit: 2);
        final result = parser.parse('>> **abc**');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<QuoteNode>());
        final quote1 = nodes[0] as QuoteNode;
        expect(quote1.children.length, 1);
        expect(quote1.children[0], isA<QuoteNode>());
        final quote2 = quote1.children[0] as QuoteNode;
        expect(quote2.children.length, 1);
        expect(quote2.children[0], isA<TextNode>());
        expect((quote2.children[0] as TextNode).text, '**abc**');
      });
    });

    group('big', () {
      // mfm.js/test/parser.ts:1331-1340
      test('mfm-js互換テスト: big', () {
        // <b><b>***abc***</b></b> → 2段階目まではネスト、***abc***はテキスト
        final parser = MfmParser().build(nestLimit: 2);
        final result = parser.parse('<b><b>***abc***</b></b>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<BoldNode>());
        final bold1 = nodes[0] as BoldNode;
        expect(bold1.children.length, 1);
        expect(bold1.children[0], isA<BoldNode>());
        final bold2 = bold1.children[0] as BoldNode;
        expect(bold2.children.length, 1);
        expect(bold2.children[0], isA<TextNode>());
        expect((bold2.children[0] as TextNode).text, '***abc***');
      });
    });

    group('bold', () {
      // mfm.js/test/parser.ts:1344-1353
      test('mfm-js互換テスト: basic', () {
        // <i><i>**abc**</i></i> → 2段階目まではネスト、**abc**はテキスト
        final parser = MfmParser().build(nestLimit: 2);
        final result = parser.parse('<i><i>**abc**</i></i>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<ItalicNode>());
        final italic1 = nodes[0] as ItalicNode;
        expect(italic1.children.length, 1);
        expect(italic1.children[0], isA<ItalicNode>());
        final italic2 = italic1.children[0] as ItalicNode;
        expect(italic2.children.length, 1);
        expect(italic2.children[0], isA<TextNode>());
        expect((italic2.children[0] as TextNode).text, '**abc**');
      });

      // mfm.js/test/parser.ts:1356-1365
      test('mfm-js互換テスト: tag', () {
        // <i><i><b>abc</b></i></i> → 2段階目まではネスト、<b>abc</b>はテキスト
        final parser = MfmParser().build(nestLimit: 2);
        final result = parser.parse('<i><i><b>abc</b></i></i>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<ItalicNode>());
        final italic1 = nodes[0] as ItalicNode;
        expect(italic1.children.length, 1);
        expect(italic1.children[0], isA<ItalicNode>());
        final italic2 = italic1.children[0] as ItalicNode;
        expect(italic2.children.length, 1);
        expect(italic2.children[0], isA<TextNode>());
        expect((italic2.children[0] as TextNode).text, '<b>abc</b>');
      });
    });

    group('small', () {
      // mfm.js/test/parser.ts:1369-1378
      test('mfm-js互換テスト: small', () {
        // <i><i><small>abc</small></i></i> → 2段階目まではネスト、<small>abc</small>はテキスト
        final parser = MfmParser().build(nestLimit: 2);
        final result = parser.parse('<i><i><small>abc</small></i></i>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<ItalicNode>());
        final italic1 = nodes[0] as ItalicNode;
        expect(italic1.children.length, 1);
        expect(italic1.children[0], isA<ItalicNode>());
        final italic2 = italic1.children[0] as ItalicNode;
        expect(italic2.children.length, 1);
        expect(italic2.children[0], isA<TextNode>());
        expect((italic2.children[0] as TextNode).text, '<small>abc</small>');
      });
    });

    group('italic', () {
      // mfm.js/test/parser.ts:1381-1390
      test('mfm-js互換テスト: italic', () {
        // <b><b><i>abc</i></b></b> → 2段階目まではネスト、<i>abc</i>はテキスト
        final parser = MfmParser().build(nestLimit: 2);
        final result = parser.parse('<b><b><i>abc</i></b></b>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<BoldNode>());
        final bold1 = nodes[0] as BoldNode;
        expect(bold1.children.length, 1);
        expect(bold1.children[0], isA<BoldNode>());
        final bold2 = bold1.children[0] as BoldNode;
        expect(bold2.children.length, 1);
        expect(bold2.children[0], isA<TextNode>());
        expect((bold2.children[0] as TextNode).text, '<i>abc</i>');
      });
    });

    group('strike', () {
      // mfm.js/test/parser.ts:1394-1403
      test('mfm-js互換テスト: basic', () {
        // <b><b>~~abc~~</b></b> → 2段階目まではネスト、~~abc~~はテキスト
        final parser = MfmParser().build(nestLimit: 2);
        final result = parser.parse('<b><b>~~abc~~</b></b>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<BoldNode>());
        final bold1 = nodes[0] as BoldNode;
        expect(bold1.children.length, 1);
        expect(bold1.children[0], isA<BoldNode>());
        final bold2 = bold1.children[0] as BoldNode;
        expect(bold2.children.length, 1);
        expect(bold2.children[0], isA<TextNode>());
        expect((bold2.children[0] as TextNode).text, '~~abc~~');
      });

      // mfm.js/test/parser.ts:1406-1415
      test('mfm-js互換テスト: tag', () {
        // <b><b><s>abc</s></b></b> → 2段階目まではネスト、<s>abc</s>はテキスト
        final parser = MfmParser().build(nestLimit: 2);
        final result = parser.parse('<b><b><s>abc</s></b></b>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<BoldNode>());
        final bold1 = nodes[0] as BoldNode;
        expect(bold1.children.length, 1);
        expect(bold1.children[0], isA<BoldNode>());
        final bold2 = bold1.children[0] as BoldNode;
        expect(bold2.children.length, 1);
        expect(bold2.children[0], isA<TextNode>());
        expect((bold2.children[0] as TextNode).text, '<s>abc</s>');
      });
    });

    group('hashtag', () {
      // mfm.js/test/parser.ts:1419-1477
      test('mfm-js互換テスト: basic', () {
        // <b>#abc(xyz)</b> → ネスト制限内ではハッシュタグとして認識
        final parser = MfmParser().build(nestLimit: 2);
        var result = parser.parse('<b>#abc(xyz)</b>');
        expect(result is Success, isTrue);
        var nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<BoldNode>());
        final bold = nodes[0] as BoldNode;
        expect(bold.children.length, 1);
        expect(bold.children[0], isA<HashtagNode>());
        expect((bold.children[0] as HashtagNode).hashtag, 'abc(xyz)');

        // <b>#abc(x(y)z)</b> → 二重ネスト括弧はハッシュタグとして認識されない
        result = parser.parse('<b>#abc(x(y)z)</b>');
        expect(result is Success, isTrue);
        nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<BoldNode>());
        final bold2 = nodes[0] as BoldNode;
        expect(bold2.children.length, 2);
        expect(bold2.children[0], isA<HashtagNode>());
        expect((bold2.children[0] as HashtagNode).hashtag, 'abc');
        expect(bold2.children[1], isA<TextNode>());
        expect((bold2.children[1] as TextNode).text, '(x(y)z)');
      });

      test('mfm-js互換テスト: outside "()"', () {
        // (#abc) → 外側の括弧はハッシュタグに含まれない
        final parser = MfmParser().build();
        final result = parser.parse('(#abc)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '(');
        expect(nodes[1], isA<HashtagNode>());
        expect((nodes[1] as HashtagNode).hashtag, 'abc');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, ')');
      });

      test('mfm-js互換テスト: outside "[]"', () {
        // [#abc] → 外側の角括弧はハッシュタグに含まれない
        final parser = MfmParser().build();
        final result = parser.parse('[#abc]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '[');
        expect(nodes[1], isA<HashtagNode>());
        expect((nodes[1] as HashtagNode).hashtag, 'abc');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, ']');
      });

      test('mfm-js互換テスト: outside "「」"', () {
        // 「#abc」 → 外側の鉤括弧はハッシュタグに含まれない
        final parser = MfmParser().build();
        final result = parser.parse('「#abc」');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '「');
        expect(nodes[1], isA<HashtagNode>());
        expect((nodes[1] as HashtagNode).hashtag, 'abc');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, '」');
      });

      test('mfm-js互換テスト: outside "（）"', () {
        // （#abc） → 外側の全角括弧はハッシュタグに含まれない
        final parser = MfmParser().build();
        final result = parser.parse('（#abc）');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '（');
        expect(nodes[1], isA<HashtagNode>());
        expect((nodes[1] as HashtagNode).hashtag, 'abc');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, '）');
      });
    });

    group('url', () {
      // mfm.js/test/parser.ts:1480-1496
      test('mfm-js互換テスト: url', () {
        final parser = MfmParser().build(nestLimit: 2);

        // <b>https://example.com/abc(xyz)</b> → URLとして認識
        var result = parser.parse('<b>https://example.com/abc(xyz)</b>');
        expect(result is Success, isTrue);
        var nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<BoldNode>());
        var bold = nodes[0] as BoldNode;
        expect(bold.children.length, 1);
        expect(bold.children[0], isA<UrlNode>());
        expect(
          (bold.children[0] as UrlNode).url,
          'https://example.com/abc(xyz)',
        );

        // <b>https://example.com/abc(x(y)z)</b> → 二重ネスト括弧はURLに含まれない
        result = parser.parse('<b>https://example.com/abc(x(y)z)</b>');
        expect(result is Success, isTrue);
        nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<BoldNode>());
        bold = nodes[0] as BoldNode;
        expect(bold.children.length, 2);
        expect(bold.children[0], isA<UrlNode>());
        expect((bold.children[0] as UrlNode).url, 'https://example.com/abc');
        expect(bold.children[1], isA<TextNode>());
        expect((bold.children[1] as TextNode).text, '(x(y)z)');
      });
    });

    group('fn', () {
      // mfm.js/test/parser.ts:1499-1508
      test('mfm-js互換テスト: fn', () {
        // <b><b>$[a b]</b></b> → 2段階目まではネスト、$[a b]はテキスト
        final parser = MfmParser().build(nestLimit: 2);
        final result = parser.parse(r'<b><b>$[a b]</b></b>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<BoldNode>());
        final bold1 = nodes[0] as BoldNode;
        expect(bold1.children.length, 1);
        expect(bold1.children[0], isA<BoldNode>());
        final bold2 = bold1.children[0] as BoldNode;
        expect(bold2.children.length, 1);
        expect(bold2.children[0], isA<TextNode>());
        expect((bold2.children[0] as TextNode).text, r'$[a b]');
      });
    });
  });
}
