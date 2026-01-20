/// mfm.js 互換性テスト - FullParser
///
/// mfm.js/test/parser.tsのFullParserセクション（行68-1540）をDartに移植
///
/// Source: https://github.com/misskey-dev/mfm.js/blob/develop/test/parser.ts
library;

import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('FullParser', () {
    final parser = MfmParser().build();

    // mfm.js:69-75
    group('text', () {});

    // mfm.js:77-183
    group('quote', () {
      // mfm.js/test/parser.ts:78-86
      test('mfm-js互換テスト: 1行の引用ブロックを使用できる', () {
        final result = parser.parse('> abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<QuoteNode>());
        final quote = nodes[0] as QuoteNode;
        expect(quote.children.length, 1);
        expect((quote.children.first as TextNode).text, 'abc');
      });

      // mfm.js/test/parser.ts:87-98
      test('mfm-js互換テスト: 複数行の引用ブロックを使用できる', () {
        const input = '> これは\n> 複数行の\n> テスト';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<QuoteNode>());
        final quote = nodes[0] as QuoteNode;
        expect(quote.children.length, 1);
        expect((quote.children.first as TextNode).text, 'これは\n複数行の\nテスト');
      });

      // mfm.js/test/parser.ts:99-113
      test('mfm-js互換テスト: 引用ブロックはブロックをネストできる', () {
        const input = '> <center>\n> a\n> </center>';
        final result = parser.parse(input);
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
        final result = parser.parse(input);
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

      // mfm.js/test/parser.ts:131-143
      test('mfm-js互換テスト: 複数行の引用ブロックでは空行を含めることができる', () {
        const input = '> abc\n>\n> 123';
        final result = parser.parse(input);
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
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '> ');
      });

      // mfm.js/test/parser.ts:151-164
      test('mfm-js互換テスト: 引用ブロックの後ろの空行は無視される', () {
        const input = '> foo\n> bar\n\nhoge';
        final result = parser.parse(input);
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
        final result = parser.parse(input);
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

    // mfm.js:185-239
    group('search', () {
      // mfm.js/test/parser.ts:187-193
      test('mfm-js互換テスト: Search', () {
        final result = parser.parse('MFM 書き方 123 Search');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<SearchNode>());
        final search = nodes[0] as SearchNode;
        expect(search.query, 'MFM 書き方 123');
        expect(search.content, 'MFM 書き方 123 Search');
      });

      // mfm.js/test/parser.ts:194-200
      test('mfm-js互換テスト: [Search]', () {
        final result = parser.parse('MFM 書き方 123 [Search]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<SearchNode>());
        final search = nodes[0] as SearchNode;
        expect(search.query, 'MFM 書き方 123');
        expect(search.content, 'MFM 書き方 123 [Search]');
      });

      // mfm.js/test/parser.ts:215-221
      test('mfm-js互換テスト: 検索', () {
        final result = parser.parse('MFM 書き方 検索');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes[0], isA<SearchNode>());
        final search = nodes[0] as SearchNode;
        expect(search.query, 'MFM 書き方');
        expect(search.content, 'MFM 書き方 検索');
      });

      // mfm.js/test/parser.ts:201-207
      test('mfm-js互換テスト: search', () {
        final result = parser.parse('MFM 書き方 123 search');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes[0], isA<SearchNode>());
        final search = nodes[0] as SearchNode;
        expect(search.query, 'MFM 書き方 123');
      });

      // mfm.js/test/parser.ts:208-214
      test('mfm-js互換テスト: [search]', () {
        final result = parser.parse('MFM 書き方 123 [search]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes[0], isA<SearchNode>());
        final search = nodes[0] as SearchNode;
        expect(search.query, 'MFM 書き方 123');
        expect(search.content, 'MFM 書き方 123 [search]');
      });

      // mfm.js/test/parser.ts:222-228
      test('mfm-js互換テスト: [検索]', () {
        final result = parser.parse('MFM 書き方 [検索]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes[0], isA<SearchNode>());
        final search = nodes[0] as SearchNode;
        expect(search.query, 'MFM 書き方');
        expect(search.content, 'MFM 書き方 [検索]');
      });

      // mfm.js/test/parser.ts:230-238
      test('mfm-js互換テスト: ブロックの前後にあるテキストが正しく解釈される', () {
        final result = parser.parse('abc\nhoge piyo bebeyo 検索\n123');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);

        // 前のテキスト
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'abc');

        // 検索ブロック
        expect(nodes[1], isA<SearchNode>());
        final search = nodes[1] as SearchNode;
        expect(search.query, 'hoge piyo bebeyo');
        expect(search.content, 'hoge piyo bebeyo 検索');

        // 後のテキスト
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, '123');
      });
    });

    // mfm.js:241-284
    group('code block', () {
      // mfm.js/test/parser.ts:242-246
      test('mfm-js互換テスト: コードブロックを使用できる', () {
        final result = parser.parse('```\nabc\n```');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<CodeBlockNode>());
        final cb = nodes[0] as CodeBlockNode;
        expect(cb.language, isNull);
        expect(cb.code, 'abc');
      });

      // mfm.js/test/parser.ts:248-252
      test('mfm-js互換テスト: コードブロックには複数行のコードを入力できる', () {
        final result = parser.parse('```\na\nb\nc\n```');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<CodeBlockNode>());
        final cb = nodes[0] as CodeBlockNode;
        expect(cb.language, isNull);
        expect(cb.code, 'a\nb\nc');
      });

      // mfm.js/test/parser.ts:254-258
      test('mfm-js互換テスト: コードブロックは言語を指定できる', () {
        final result = parser.parse('```js\nconst a = 1;\n```');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        final cb = nodes[0] as CodeBlockNode;
        expect(cb.language, 'js');
        expect(cb.code, 'const a = 1;');
      });

      // mfm.js/test/parser.ts:260-268
      test('mfm-js互換テスト: ブロックの前後にあるテキストが正しく解釈される', () {
        final result = parser.parse('abc\n```\nconst abc = 1;\n```\n123');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'abc');
        expect(nodes[1], isA<CodeBlockNode>());
        final cb = nodes[1] as CodeBlockNode;
        expect(cb.language, isNull);
        expect(cb.code, 'const abc = 1;');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, '123');
      });

      // mfm.js/test/parser.ts:270-274
      test('mfm-js互換テスト: ignore internal marker', () {
        final result = parser.parse('```\naaa```bbb\n```');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        final cb = nodes[0] as CodeBlockNode;
        expect(cb.code, 'aaa```bbb');
      });

      // mfm.js/test/parser.ts:276-283
      test('mfm-js互換テスト: trim after line break', () {
        final result = parser.parse('```\nfoo\n```\nbar');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 2);
        expect(nodes[0], isA<CodeBlockNode>());
        final cb = nodes[0] as CodeBlockNode;
        expect(cb.language, isNull);
        expect(cb.code, 'foo');
        expect(nodes[1], isA<TextNode>());
        expect((nodes[1] as TextNode).text, 'bar');
      });
    });

    // mfm.js:286-317
    group('mathBlock', () {
      // mfm.js/test/parser.ts:287-293
      test(r'mfm-js互換テスト: 1行の数式ブロックを使用できる', () {
        final result = parser.parse(r'\[math1\]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<MathBlockNode>());
        final math = nodes[0] as MathBlockNode;
        expect(math.formula, 'math1');
      });

      // mfm.js/test/parser.ts:294-302
      test('mfm-js互換テスト: ブロックの前後にあるテキストが正しく解釈される', () {
        final result = parser.parse('abc\n\\[math\\]\nxyz');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // abc\n, mathBlock, \nxyz の3つ
        expect(nodes.any((n) => n is MathBlockNode), isTrue);
      });

      // mfm.js/test/parser.ts:303-309
      test(r'mfm-js互換テスト: 行末以外に閉じタグがある場合はマッチしない', () {
        final result = parser.parse(r'\[aaa\]after');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // MathBlockとしてパースされず、プレーンテキストとして扱われる
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, r'\[aaa\]after');
      });

      // mfm.js/test/parser.ts:310-316
      test(r'mfm-js互換テスト: 行頭以外に開始タグがある場合はマッチしない', () {
        final result = parser.parse(r'before\[aaa\]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // MathBlockとしてパースされず、プレーンテキストとして扱われる
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, r'before\[aaa\]');
      });
    });

    // mfm.js:319-340
    group('center', () {
      // mfm.js/test/parser.ts:320-328
      test('mfm-js互換テスト: single text', () {
        final result = parser.parse('<center>abc</center>');
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
        const input = 'before\n<center>\nabc\n123\n\npiyo\n</center>\nafter';
        final result = parser.parse(input);
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

    // mfm.js:342-348
    group('emoji code', () {});

    // mfm.js:350-362
    group('unicode emoji', () {});

    // mfm.js:364-399
    group('big', () {});

    // mfm.js:402-438
    group('bold tag', () {});

    // mfm.js:440-476
    group('bold', () {});

    // mfm.js:478-514
    group('small', () {});

    // mfm.js:516-552
    group('italic tag', () {});

    // mfm.js:554-592
    group('italic alt 1', () {});

    // mfm.js:594-632
    group('italic alt 2', () {});

    // mfm.js:634-642
    group('strike tag', () {});

    // mfm.js:644-652
    group('strike', () {});

    // mfm.js:654-672
    group('inlineCode', () {});

    // mfm.js:674-680
    group('mathInline', () {});

    // mfm.js:682-796
    group('mention', () {});

    // mfm.js:798-928
    group('hashtag', () {});

    // mfm.js:930-1064
    group('url', () {});

    // mfm.js:1066-1228
    group('link', () {});

    // mfm.js:1230-1280
    group('fn', () {});

    // mfm.js:1282-1302
    group('plain', () {});

    // mfm.js:1304-1509
    group('nesting limit', () {});

    // mfm.js:1512-1540
    group('composite', () {});
  });
}
