/// mfm.js 互換性テスト - FullParser
///
/// mfm.js/test/parser.tsのFullParserセクション（行68-1540）をDartに移植
///
/// Source: https://github.com/misskey-dev/mfm.js/blob/develop/test/parser.ts
library;

import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('FullParser', () {
    final parser = MfmParser().build();

    // mfm.js:69-75
    group('text', () {
      // mfm.js/test/parser.ts:70-74
      test('mfm-js互換テスト: FullParser text - basic', () {
        final result = parser.parse('abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('abc')]);
      });
    });

    // mfm.js:77-183
    group('quote', () {
      // mfm.js/test/parser.ts:78-86
      test('mfm-js互換テスト: 1行の引用ブロックを使用できる', () {
        final result = parser.parse('> abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const QuoteNode([TextNode('abc')]),
        ]);
      });

      // mfm.js/test/parser.ts:87-98
      test('mfm-js互換テスト: 複数行の引用ブロックを使用できる', () {
        const input = '> これは\n> 複数行の\n> テスト';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const QuoteNode([TextNode('これは\n複数行の\nテスト')]),
        ]);
      });

      // mfm.js/test/parser.ts:99-113
      test('mfm-js互換テスト: 引用ブロックはブロックをネストできる', () {
        const input = '> <center>\n> a\n> </center>';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // mfm-js期待値: 改行なし
        expect(nodes, [
          const QuoteNode([
            CenterNode([TextNode('a')]),
          ]),
        ]);
      });

      // mfm.js/test/parser.ts:114-129
      test('mfm-js互換テスト: 引用ブロックはインライン構文を含んだブロックをネストできる', () {
        const input = '> <center>\n> I\'m @ai, An bot of misskey!\n> </center>';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // mfm-js期待値: 先頭に改行なし / 末尾に改行なし
        expect(nodes, [
          const QuoteNode([
            CenterNode([
              TextNode("I'm "),
              MentionNode(username: 'ai', acct: '@ai'),
              TextNode(', An bot of misskey!'),
            ]),
          ]),
        ]);
      });

      // mfm.js/test/parser.ts:131-143
      test('mfm-js互換テスト: 複数行の引用ブロックでは空行を含めることができる', () {
        const input = '> abc\n>\n> 123';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const QuoteNode([TextNode('abc\n\n123')]),
        ]);
      });

      // mfm.js/test/parser.ts:144-150
      test('mfm-js互換テスト: 1行の引用ブロックを空行にはできない', () {
        // QuoteNodeではなくTextNodeになる
        const input = '> ';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('> ')]);
      });

      // mfm.js/test/parser.ts:151-164
      test('mfm-js互換テスト: 引用ブロックの後ろの空行は無視される', () {
        const input = '> foo\n> bar\n\nhoge';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // mfm-js期待値: 空行が除去されて'hoge'のみ
        expect(nodes, [
          const QuoteNode([TextNode('foo\nbar')]),
          const TextNode('hoge'),
        ]);
      });

      // mfm.js/test/parser.ts:165-182
      test('mfm-js互換テスト: 2つの引用行の間に空行がある場合は2つの引用ブロックが生成される', () {
        const input = '> foo\n\n> bar\n\nhoge';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // mfm-js期待値: 3つのノード（QuoteNode, QuoteNode, TextNode）
        expect(nodes, [
          const QuoteNode([TextNode('foo')]),
          const QuoteNode([TextNode('bar')]),
          const TextNode('hoge'),
        ]);
      });
    });

    // mfm.js:185-239
    group('search', () {
      // mfm.js/test/parser.ts:187-193
      test('mfm-js互換テスト: Search', () {
        final result = parser.parse('MFM 書き方 123 Search');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const SearchNode(
            query: 'MFM 書き方 123',
            content: 'MFM 書き方 123 Search',
          ),
        ]);
      });

      // mfm.js/test/parser.ts:194-200
      test('mfm-js互換テスト: [Search]', () {
        final result = parser.parse('MFM 書き方 123 [Search]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const SearchNode(
            query: 'MFM 書き方 123',
            content: 'MFM 書き方 123 [Search]',
          ),
        ]);
      });

      // mfm.js/test/parser.ts:215-221
      test('mfm-js互換テスト: 検索', () {
        final result = parser.parse('MFM 書き方 検索');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const SearchNode(query: 'MFM 書き方', content: 'MFM 書き方 検索'),
        ]);
      });

      // mfm.js/test/parser.ts:201-207
      test('mfm-js互換テスト: search', () {
        final result = parser.parse('MFM 書き方 123 search');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const SearchNode(query: 'MFM 書き方 123', content: 'MFM 書き方 123 search'),
        ]);
      });

      // mfm.js/test/parser.ts:208-214
      test('mfm-js互換テスト: [search]', () {
        final result = parser.parse('MFM 書き方 123 [search]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const SearchNode(
            query: 'MFM 書き方 123',
            content: 'MFM 書き方 123 [search]',
          ),
        ]);
      });

      // mfm.js/test/parser.ts:222-228
      test('mfm-js互換テスト: [検索]', () {
        final result = parser.parse('MFM 書き方 [検索]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const SearchNode(query: 'MFM 書き方', content: 'MFM 書き方 [検索]'),
        ]);
      });

      // mfm.js/test/parser.ts:230-238
      test('mfm-js互換テスト: ブロックの前後にあるテキストが正しく解釈される', () {
        final result = parser.parse('abc\nhoge piyo bebeyo 検索\n123');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('abc'),
          const SearchNode(
            query: 'hoge piyo bebeyo',
            content: 'hoge piyo bebeyo 検索',
          ),
          const TextNode('123'),
        ]);
      });
    });

    // mfm.js:241-284
    group('code block', () {
      // mfm.js/test/parser.ts:242-246
      test('mfm-js互換テスト: コードブロックを使用できる', () {
        final result = parser.parse('```\nabc\n```');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const CodeBlockNode(code: 'abc'),
        ]);
      });

      // mfm.js/test/parser.ts:248-252
      test('mfm-js互換テスト: コードブロックには複数行のコードを入力できる', () {
        final result = parser.parse('```\na\nb\nc\n```');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const CodeBlockNode(code: 'a\nb\nc'),
        ]);
      });

      // mfm.js/test/parser.ts:254-258
      test('mfm-js互換テスト: コードブロックは言語を指定できる', () {
        final result = parser.parse('```js\nconst a = 1;\n```');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const CodeBlockNode(code: 'const a = 1;', language: 'js'),
        ]);
      });

      // mfm.js/test/parser.ts:260-268
      test('mfm-js互換テスト: ブロックの前後にあるテキストが正しく解釈される', () {
        final result = parser.parse('abc\n```\nconst abc = 1;\n```\n123');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('abc'),
          const CodeBlockNode(code: 'const abc = 1;'),
          const TextNode('123'),
        ]);
      });

      // mfm.js/test/parser.ts:270-274
      test('mfm-js互換テスト: ignore internal marker', () {
        final result = parser.parse('```\naaa```bbb\n```');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const CodeBlockNode(code: 'aaa```bbb'),
        ]);
      });

      // mfm.js/test/parser.ts:276-283
      test('mfm-js互換テスト: trim after line break', () {
        final result = parser.parse('```\nfoo\n```\nbar');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const CodeBlockNode(code: 'foo'),
          const TextNode('bar'),
        ]);
      });
    });

    // mfm.js:286-317
    group('mathBlock', () {
      // mfm.js/test/parser.ts:287-293
      test(r'mfm-js互換テスト: 1行の数式ブロックを使用できる', () {
        final result = parser.parse(r'\[math1\]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MathBlockNode('math1'),
        ]);
      });

      // mfm.js/test/parser.ts:294-302
      test('mfm-js互換テスト: ブロック前後の境界改行を数式ブロックが消費する', () {
        final result = parser.parse('abc\n\\[math\\]\nxyz');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('abc'),
          const MathBlockNode('math'),
          const TextNode('xyz'),
        ]);
      });

      // mfm.js/test/parser.ts:303-309
      test(r'mfm-js互換テスト: 行末以外に閉じタグがある場合はマッチしない', () {
        final result = parser.parse(r'\[aaa\]after');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // MathBlockとしてパースされず、プレーンテキストとして扱われる
        expect(nodes, [const TextNode(r'\[aaa\]after')]);
      });

      // mfm.js/test/parser.ts:310-316
      test(r'mfm-js互換テスト: 行頭以外に開始タグがある場合はマッチしない', () {
        final result = parser.parse(r'before\[aaa\]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // MathBlockとしてパースされず、プレーンテキストとして扱われる
        expect(nodes, [const TextNode(r'before\[aaa\]')]);
      });
    });

    // mfm.js:319-340
    group('center', () {
      // mfm.js/test/parser.ts:320-328
      test('mfm-js互換テスト: single text', () {
        final result = parser.parse('<center>abc</center>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const CenterNode([TextNode('abc')]),
        ]);
      });

      // mfm.js/test/parser.ts:329-339
      test('mfm-js互換テスト: multiple text', () {
        const input = 'before\n<center>\nabc\n123\n\npiyo\n</center>\nafter';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('before'),
          const CenterNode([TextNode('abc\n123\n\npiyo')]),
          const TextNode('after'),
        ]);
      });
    });

    // mfm.js:342-348
    group('emoji code', () {
      // mfm.js/test/parser.ts:343-347
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse(':emoji:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const EmojiCodeNode('emoji'),
        ]);
      });
    });

    // mfm.js:350-362
    group('unicode emoji', () {
      // mfm.js/test/parser.ts:351-355
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse('今起きた😇');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('今起きた'),
          const UnicodeEmojiNode('😇'),
        ]);
      });

      // mfm.js/test/parser.ts:357-360
      test('mfm-js互換テスト: keycap number sign', () {
        final result = parser.parse('abc#️⃣123');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('abc'),
          const UnicodeEmojiNode('#️⃣'),
          const TextNode('123'),
        ]);
      });
    });

    // mfm.js:364-399
    group('big', () {
      // mfm.js/test/parser.ts:365-373
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse('***abc***');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const FnNode(name: 'tada', args: {}, children: [TextNode('abc')]),
        ]);
      });

      // mfm.js/test/parser.ts:374-386
      test('mfm-js互換テスト: 内容にはインライン構文を利用できる', () {
        final result = parser.parse('***123**abc**123***');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const FnNode(
            name: 'tada',
            args: {},
            children: [
              TextNode('123'),
              BoldNode([TextNode('abc')]),
              TextNode('123'),
            ],
          ),
        ]);
      });

      // mfm.js/test/parser.ts:387-399
      test('mfm-js互換テスト: 内容は改行できる', () {
        final result = parser.parse('***123\n**abc**\n123***');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const FnNode(
            name: 'tada',
            args: {},
            children: [
              TextNode('123\n'),
              BoldNode([TextNode('abc')]),
              TextNode('\n123'),
            ],
          ),
        ]);
      });
    });

    // mfm.js:402-438
    group('bold tag', () {
      // mfm.js/test/parser.ts:403-411
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse('<b>abc</b>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const BoldNode([TextNode('abc')]),
        ]);
      });

      // mfm.js/test/parser.ts:412-424
      test('mfm-js互換テスト: inline syntax allowed inside', () {
        final result = parser.parse('<b>123~~abc~~123</b>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const BoldNode([
            TextNode('123'),
            StrikeNode([TextNode('abc')]),
            TextNode('123'),
          ]),
        ]);
      });

      // mfm.js/test/parser.ts:425-437
      test('mfm-js互換テスト: line breaks', () {
        final result = parser.parse('<b>123\n~~abc~~\n123</b>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const BoldNode([
            TextNode('123\n'),
            StrikeNode([TextNode('abc')]),
            TextNode('\n123'),
          ]),
        ]);
      });
    });

    // mfm.js:440-476
    group('bold', () {
      // mfm.js/test/parser.ts:441-449
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse('**bold**');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const BoldNode([TextNode('bold')]),
        ]);
      });

      // mfm.js/test/parser.ts:450-461
      test('mfm-js互換テスト: 内容にはインライン構文を利用できる', () {
        final result = parser.parse('**123~~abc~~123**');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const BoldNode([
            TextNode('123'),
            StrikeNode([TextNode('abc')]),
            TextNode('123'),
          ]),
        ]);
      });

      // mfm.js/test/parser.ts:463-475
      test('mfm-js互換テスト: 内容は改行できる', () {
        final result = parser.parse('**line1\nline2**');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const BoldNode([TextNode('line1\nline2')]),
        ]);
      });
    });

    // mfm.js:478-514
    group('small', () {
      // mfm.js/test/parser.ts:479-487
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse('<small>abc</small>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const SmallNode([TextNode('abc')]),
        ]);
      });

      // mfm.js/test/parser.ts:488-499
      test('mfm-js互換テスト: 内容にはインライン構文を利用できる', () {
        final result = parser.parse('<small>abc**123**abc</small>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const SmallNode([
            TextNode('abc'),
            BoldNode([TextNode('123')]),
            TextNode('abc'),
          ]),
        ]);
      });

      // mfm.js/test/parser.ts:501-513
      test('mfm-js互換テスト: 内容は改行できる', () {
        final result = parser.parse('<small>abc\n**123**\nabc</small>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const SmallNode([
            TextNode('abc\n'),
            BoldNode([TextNode('123')]),
            TextNode('\nabc'),
          ]),
        ]);
      });
    });

    // mfm.js:516-552
    group('italic tag', () {
      // mfm.js/test/parser.ts:517-525
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse('<i>abc</i>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const ItalicNode([TextNode('abc')]),
        ]);
      });

      // mfm.js/test/parser.ts:526-538
      test('mfm-js互換テスト: 内容にはインライン構文を利用できる', () {
        final result = parser.parse('<i>abc**123**abc</i>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const ItalicNode([
            TextNode('abc'),
            BoldNode([TextNode('123')]),
            TextNode('abc'),
          ]),
        ]);
      });

      // mfm.js/test/parser.ts:539-551
      test('mfm-js互換テスト: 内容は改行できる', () {
        final result = parser.parse('<i>abc\n**123**\nabc</i>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const ItalicNode([
            TextNode('abc\n'),
            BoldNode([TextNode('123')]),
            TextNode('\nabc'),
          ]),
        ]);
      });
    });

    // mfm.js:554-592
    group('italic alt 1', () {
      // mfm.js/test/parser.ts:555-563
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse('*abc*');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const ItalicNode([TextNode('abc')]),
        ]);
      });

      // mfm.js/test/parser.ts:565-575
      test('mfm-js互換テスト: basic 2', () {
        final result = parser.parse('before *abc* after');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('before '),
          const ItalicNode([TextNode('abc')]),
          const TextNode(' after'),
        ]);
      });

      // mfm.js/test/parser.ts:577-591
      test(
        'mfm-js互換テスト: ignore a italic syntax if the before char is '
        'neither a space nor an LF nor [^a-z0-9]i',
        () {
          // 英数字の直後では無視される
          var result = parser.parse('before*abc*after');
          expect(result is Success, isTrue);
          var nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [const TextNode('before*abc*after')]);

          // 日本語の直後では許可される
          result = parser.parse('あいう*abc*えお');
          expect(result is Success, isTrue);
          nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const TextNode('あいう'),
            const ItalicNode([TextNode('abc')]),
            const TextNode('えお'),
          ]);
        },
      );
    });

    // mfm.js:594-632
    group('italic alt 2', () {
      // mfm.js/test/parser.ts:595-603
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse('_abc_');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const ItalicNode([TextNode('abc')]),
        ]);
      });

      // mfm.js/test/parser.ts:605-615
      test('mfm-js互換テスト: basic 2', () {
        final result = parser.parse('before _abc_ after');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('before '),
          const ItalicNode([TextNode('abc')]),
          const TextNode(' after'),
        ]);
      });

      // mfm.js/test/parser.ts:617-631
      test(
        'mfm-js互換テスト: ignore a italic syntax if the before char is '
        'neither a space nor an LF nor [^a-z0-9]i',
        () {
          // 英数字の直後では無視される
          var result = parser.parse('before_abc_after');
          expect(result is Success, isTrue);
          var nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [const TextNode('before_abc_after')]);

          // 日本語の直後では許可される
          result = parser.parse('あいう_abc_えお');
          expect(result is Success, isTrue);
          nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const TextNode('あいう'),
            const ItalicNode([TextNode('abc')]),
            const TextNode('えお'),
          ]);
        },
      );
    });

    // mfm.js:634-642
    group('strike tag', () {
      // mfm.js/test/parser.ts:635-641
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse('<s>abc</s>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const StrikeNode([TextNode('abc')]),
        ]);
      });
    });

    // mfm.js:644-652
    group('strike', () {
      // mfm.js/test/parser.ts:645-651
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse('~~strike~~');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const StrikeNode([TextNode('strike')]),
        ]);
      });
    });

    // mfm.js:654-672
    group('inlineCode', () {
      // mfm.js/test/parser.ts:655-659
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse('AiScript: `#abc = 2`');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('AiScript: '),
          const InlineCodeNode('#abc = 2'),
        ]);
      });

      // mfm.js/test/parser.ts:661-665
      test('mfm-js互換テスト: disallow line break', () {
        final result = parser.parse('`foo\nbar`');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('`foo\nbar`')]);
      });

      // mfm.js/test/parser.ts:667-671
      test('mfm-js互換テスト: disallow ´', () {
        final result = parser.parse('`foo´bar`');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('`foo´bar`')]);
      });
    });

    // mfm.js:674-680
    group('mathInline', () {
      // mfm.js/test/parser.ts:675-679
      test(r'mfm-js互換テスト: basic', () {
        final result = parser.parse(r'\(x = 2\)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MathInlineNode('x = 2'),
        ]);
      });
    });

    // mfm.js:682-796
    group('mention', () {
      // mfm.js/test/parser.ts:683-686
      test('mfm-js互換テスト: basic', () {
        const input = '@user';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(username: 'user', acct: '@user'),
        ]);
      });

      // mfm.js/test/parser.ts:689-693
      test('mfm-js互換テスト: basic 2', () {
        const input = 'before @abc after';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('before '),
          const MentionNode(username: 'abc', acct: '@abc'),
          const TextNode(' after'),
        ]);
      });

      // mfm.js/test/parser.ts:695-699
      test('mfm-js互換テスト: basic remote', () {
        const input = '@user@misskey.io';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(
            username: 'user',
            host: 'misskey.io',
            acct: '@user@misskey.io',
          ),
        ]);
      });

      // mfm.js/test/parser.ts:701-705
      test('mfm-js互換テスト: basic remote 2', () {
        const input = 'before @abc@misskey.io after';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('before '),
          const MentionNode(
            username: 'abc',
            host: 'misskey.io',
            acct: '@abc@misskey.io',
          ),
          const TextNode(' after'),
        ]);
      });

      // mfm.js/test/parser.ts:707-711
      test('mfm-js互換テスト: basic remote 3', () {
        const input = 'before\n@abc@misskey.io\nafter';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('before\n'),
          const MentionNode(
            username: 'abc',
            host: 'misskey.io',
            acct: '@abc@misskey.io',
          ),
          const TextNode('\nafter'),
        ]);
      });

      // mfm.js/test/parser.ts:713-717
      test('mfm-js互換テスト: ignore format of mail address', () {
        const input = 'abc@example.com';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('abc@example.com')]);
      });

      // mfm.js/test/parser.ts:719-723
      test(
        'mfm-js互換テスト: detect as a mention if the before char is [^a-z0-9]i',
        () {
          const input = 'あいう@abc';
          final result = parser.parse(input);
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const TextNode('あいう'),
            const MentionNode(username: 'abc', acct: '@abc'),
          ]);
        },
      );

      // mfm.js/test/parser.ts:725-729
      test('mfm-js互換テスト: invalid char only username', () {
        const input = '@-';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('@-')]);
      });

      // mfm.js/test/parser.ts:731-735
      test('mfm-js互換テスト: invalid char only hostname', () {
        const input = '@abc@.';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('@abc@.')]);
      });

      // mfm.js/test/parser.ts:737-741
      test('mfm-js互換テスト: ハイフンを含むユーザー名（中間）を解析できる', () {
        const input = '@user-name';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(username: 'user-name', acct: '@user-name'),
        ]);
      });

      // mfm.js/test/parser.ts:743-747
      test('mfm-js互換テスト: allow "." in username', () {
        const input = '@bsky.brid.gy@bsky.brid.gy';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(
            username: 'bsky.brid.gy',
            host: 'bsky.brid.gy',
            acct: '@bsky.brid.gy@bsky.brid.gy',
          ),
        ]);
      });

      // mfm.js/test/parser.ts:743-747
      test('mfm-js互換テスト: ピリオドを含むユーザー名（中間）を解析できる', () {
        const input = '@user.name';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(username: 'user.name', acct: '@user.name'),
        ]);
      });

      // mfm.js/test/parser.ts:749-753
      test('mfm-js互換テスト: disallow "-" in head of username', () {
        const input = '@-user';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('@-user')]);
      });

      // mfm.js/test/parser.ts:755-759
      test('mfm-js互換テスト: 末尾ハイフンは除去される', () {
        const input = '@user-';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(username: 'user', acct: '@user'),
          const TextNode('-'),
        ]);
      });

      // mfm.js/test/parser.ts:767-771
      test('mfm-js互換テスト: 末尾ピリオドは除去される', () {
        const input = '@user.';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(username: 'user', acct: '@user'),
          const TextNode('.'),
        ]);
      });

      // mfm.js/test/parser.ts:773-777
      test('mfm-js互換テスト: disallow "." in head of hostname', () {
        const input = '@abc@.aaa';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('@abc@.aaa')]);
      });

      // mfm.js/test/parser.ts:779-783
      test('mfm-js互換テスト: disallow "." in tail of hostname', () {
        const input = '@abc@aaa.';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(username: 'abc', host: 'aaa', acct: '@abc@aaa'),
          const TextNode('.'),
        ]);
      });

      // mfm.js/test/parser.ts:785-789
      test('mfm-js互換テスト: disallow "-" in head of hostname', () {
        const input = '@abc@-aaa';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('@abc@-aaa')]);
      });

      // mfm.js/test/parser.ts:791-795
      test('mfm-js互換テスト: disallow "-" in tail of hostname', () {
        const input = '@abc@aaa-';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(username: 'abc', host: 'aaa', acct: '@abc@aaa'),
          const TextNode('-'),
        ]);
      });
    });

    // mfm.js:798-928
    group('hashtag', () {
      // mfm.js/test/parser.ts:799-803
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse('#abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('abc'),
        ]);
      });

      // mfm.js/test/parser.ts:805-809
      test('mfm-js互換テスト: basic 2', () {
        final result = parser.parse('before #abc after');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('before '),
          const HashtagNode('abc'),
          const TextNode(' after'),
        ]);
      });

      // mfm.js/test/parser.ts:811-815
      test('mfm-js互換テスト: with keycap number sign', () {
        final result = parser.parse('#️⃣abc123 #abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const UnicodeEmojiNode('#️⃣'),
          const TextNode('abc123 '),
          const HashtagNode('abc'),
        ]);
      });

      // mfm.js/test/parser.ts:817-822
      test('mfm-js互換テスト: with keycap number sign 2', () {
        final result = parser.parse('abc\n#️⃣abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('abc\n'),
          const UnicodeEmojiNode('#️⃣'),
          const TextNode('abc'),
        ]);
      });

      // mfm.js/test/parser.ts:824-832
      test(
        'mfm-js互換テスト: ignore a hashtag if the before char is '
        'neither a space nor an LF nor [^a-z0-9]i',
        () {
          var result = parser.parse('abc#abc');
          expect(result is Success, isTrue);
          var nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [const TextNode('abc#abc')]);

          result = parser.parse('あいう#abc');
          expect(result is Success, isTrue);
          nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const TextNode('あいう'),
            const HashtagNode('abc'),
          ]);
        },
      );

      // mfm.js/test/parser.ts:834-838
      test('mfm-js互換テスト: ignore comma and period', () {
        final result = parser.parse('Foo #bar, baz #piyo.');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('Foo '),
          const HashtagNode('bar'),
          const TextNode(', baz '),
          const HashtagNode('piyo'),
          const TextNode('.'),
        ]);
      });

      // mfm.js/test/parser.ts:840-844
      test('mfm-js互換テスト: ignore exclamation mark', () {
        final result = parser.parse('#Foo!');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('Foo'),
          const TextNode('!'),
        ]);
      });

      // mfm.js/test/parser.ts:846-850
      test('mfm-js互換テスト: ignore colon', () {
        final result = parser.parse('#Foo:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('Foo'),
          const TextNode(':'),
        ]);
      });

      // mfm.js/test/parser.ts:852-856
      test('mfm-js互換テスト: ignore single quote', () {
        final result = parser.parse("#Foo'");
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('Foo'),
          const TextNode("'"),
        ]);
      });

      // mfm.js/test/parser.ts:858-862
      test('mfm-js互換テスト: ignore double quote', () {
        final result = parser.parse('#Foo"');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('Foo'),
          const TextNode('"'),
        ]);
      });

      // mfm.js/test/parser.ts:864-868
      test('mfm-js互換テスト: ignore square bracket', () {
        final result = parser.parse('#Foo]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('Foo'),
          const TextNode(']'),
        ]);
      });

      // mfm.js/test/parser.ts:870-874
      test('mfm-js互換テスト: ignore slash', () {
        final result = parser.parse('#foo/bar');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('foo'),
          const TextNode('/bar'),
        ]);
      });

      // mfm.js/test/parser.ts:876-880
      test('mfm-js互換テスト: ignore angle bracket', () {
        final result = parser.parse('#foo<bar>');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('foo'),
          const TextNode('<bar>'),
        ]);
      });

      // mfm.js/test/parser.ts:882-886
      test('mfm-js互換テスト: allow including number', () {
        final result = parser.parse('#foo123');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('foo123'),
        ]);
      });

      // mfm.js/test/parser.ts:888-892
      test('mfm-js互換テスト: with brackets "()"', () {
        final result = parser.parse('(#foo)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('('),
          const HashtagNode('foo'),
          const TextNode(')'),
        ]);
      });

      // mfm.js/test/parser.ts:894-898
      test('mfm-js互換テスト: with brackets "「」"', () {
        final result = parser.parse('「#foo」');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('「'),
          const HashtagNode('foo'),
          const TextNode('」'),
        ]);
      });

      // mfm.js/test/parser.ts:900-904
      test('mfm-js互換テスト: with mixed brackets', () {
        final result = parser.parse('「#foo(bar)」');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('「'),
          const HashtagNode('foo(bar)'),
          const TextNode('」'),
        ]);
      });

      // mfm.js/test/parser.ts:906-910
      test('mfm-js互換テスト: with brackets "()" (space before)', () {
        final result = parser.parse('(bar #foo)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('(bar '),
          const HashtagNode('foo'),
          const TextNode(')'),
        ]);
      });

      // mfm.js/test/parser.ts:912-916
      test('mfm-js互換テスト: with brackets "「」" (space before)', () {
        final result = parser.parse('「bar #foo」');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('「bar '),
          const HashtagNode('foo'),
          const TextNode('」'),
        ]);
      });

      // mfm.js/test/parser.ts:918-922
      test('mfm-js互換テスト: disallow number only', () {
        final result = parser.parse('#123');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('#123')]);
      });

      // mfm.js/test/parser.ts:924-928
      test('mfm-js互換テスト: disallow number only (with brackets)', () {
        final result = parser.parse('(#123)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('(#123)')]);
      });
    });

    // mfm.js:930-1064
    group('url', () {
      group('生URL（フルパーサー経由）', () {
        // mfm.js/test/parser.ts:932-938
        test('mfm-js互換テスト: basic', () {
          final result = parser.parse('https://example.com');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const UrlNode(url: 'https://example.com'),
          ]);
        });

        // mfm.js/test/parser.ts:940-948
        test('mfm-js互換テスト: with other texts', () {
          final result = parser.parse(
            'official instance: https://misskey.io/@ai.',
          );
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const TextNode('official instance: '),
            const UrlNode(url: 'https://misskey.io/@ai'),
            const TextNode('.'),
          ]);
        });

        // mfm.js/test/parser.ts:976-982
        test('mfm-js互換テスト: with comma', () {
          final result = parser.parse('https://example.com/foo?bar=a,b');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const UrlNode(url: 'https://example.com/foo?bar=a,b'),
          ]);
        });

        group('括弧のネスト処理', () {
          // mfm.js/test/parser.ts:993-999
          test('mfm-js互換テスト: with brackets', () {
            final result = parser.parse('https://example.com/foo(bar)');
            expect(result is Success, isTrue);
            final nodes = (result as Success).value as List<MfmNode>;
            expect(nodes, [
              const UrlNode(url: 'https://example.com/foo(bar)'),
            ]);
          });
        });

        // mfm.js/test/parser.ts:950-991
        group('末尾の無効文字除去', () {
          test('mfm-js互換テスト: 末尾のピリオドを除去', () {
            final result = parser.parse('https://example.com.');
            expect(result is Success, isTrue);
            final nodes = (result as Success).value as List<MfmNode>;
            expect(nodes, [
              const UrlNode(url: 'https://example.com'),
              const TextNode('.'),
            ]);
          });

          test('mfm-js互換テスト: 末尾のカンマを除去', () {
            final result = parser.parse('https://example.com,');
            expect(result is Success, isTrue);
            final nodes = (result as Success).value as List<MfmNode>;
            expect(nodes, [
              const UrlNode(url: 'https://example.com'),
              const TextNode(','),
            ]);
          });

          test('mfm-js互換テスト: 末尾の複数ピリオド・カンマを除去', () {
            final result = parser.parse('https://example.com.,.');
            expect(result is Success, isTrue);
            final nodes = (result as Success).value as List<MfmNode>;
            expect(nodes, [
              const UrlNode(url: 'https://example.com'),
              const TextNode('.,.'),
            ]);
          });
        });
      });

      // mfm.js/test/parser.ts:931-1063
      group('mfm-js互換テスト', () {
        group('edge cases', () {
          test('mfm-js互換テスト: disallow period only', () {
            // mfm-js: https://. はURLとして認識されず、テキストとして扱われる
            final result = parser.parse('https://.');
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [const TextNode('https://.')]);
          });
        });

        group('parent brackets handling', () {
          test('mfm-js互換テスト: ignore parent brackets', () {
            // mfm-js: 親括弧内のURLは括弧を含まない
            final result = parser.parse('(https://example.com/foo)');
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [
              const TextNode('('),
              const UrlNode(url: 'https://example.com/foo'),
              const TextNode(')'),
            ]);
          });

          test('mfm-js互換テスト: ignore parent brackets (2)', () {
            // mfm-js: テキスト後の親括弧内URLも同様
            final result = parser.parse('(foo https://example.com/foo)');
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [
              const TextNode('(foo '),
              const UrlNode(url: 'https://example.com/foo'),
              const TextNode(')'),
            ]);
          });

          test(
            'mfm-js互換テスト: ignore parent brackets with internal brackets',
            () {
              // mfm-js: 内部括弧を含むURLは内部括弧を保持し、親括弧は除外
              final result = parser.parse('(https://example.com/foo(bar))');
              expect(result is Success, isTrue);
              final nodes = result.value;
              expect(nodes, [
                const TextNode('('),
                const UrlNode(url: 'https://example.com/foo(bar)'),
                const TextNode(')'),
              ]);
            },
          );

          test('mfm-js互換テスト: ignore parent []', () {
            // mfm-js: 角括弧内のURLも同様に処理
            final result = parser.parse('foo [https://example.com/foo] bar');
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [
              const TextNode('foo ['),
              const UrlNode(url: 'https://example.com/foo'),
              const TextNode('] bar'),
            ]);
          });
        });

        group('non-ascii and xss prevention', () {
          test(
            'mfm-js互換テスト: ignore non-ascii characters contained url '
            'without angle brackets',
            () {
              // mfm-js: 非ASCII文字を含むURLはブラケットなしではテキストとして扱う
              final result = parser.parse('https://大石泉すき.example.com');
              expect(result is Success, isTrue);
              final nodes = result.value;
              expect(nodes, [const TextNode('https://大石泉すき.example.com')]);
            },
          );

          test(
            'mfm-js互換テスト: match non-ascii characters contained url '
            'with angle brackets',
            () {
              // mfm-js: ブラケット付きなら非ASCII文字を含むURLも認識
              final result = parser.parse('<https://大石泉すき.example.com>');
              expect(result is Success, isTrue);
              final nodes = result.value;
              expect(nodes, [
                const UrlNode(
                  url: 'https://大石泉すき.example.com',
                  brackets: true,
                ),
              ]);
            },
          );

          test('mfm-js互換テスト: prevent xss', () {
            // mfm-js: javascript: スキームはURLとして認識しない（XSS防止）
            final result = parser.parse('javascript:foo');
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [const TextNode('javascript:foo')]);
          });
        });
      });
    });

    // mfm.js:1066-1228
    group('link', () {
      group('通常リンク（フルパーサー経由）', () {
        // mfm.js/test/parser.ts:1067-1076
        test('mfm-js互換テスト: basic', () {
          final result = parser.parse('[Example](https://example.com)');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const LinkNode(
              silent: false,
              url: 'https://example.com',
              children: [TextNode('Example')],
            ),
          ]);
        });

        // mfm.js/test/parser.ts:1089-1098
        test('mfm-js互換テスト: with angle brackets url', () {
          final result = parser.parse(
            '[official instance](<https://misskey.io/@ai>).',
          );
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const LinkNode(
              silent: false,
              url: 'https://misskey.io/@ai',
              children: [TextNode('official instance')],
            ),
            const TextNode('.'),
          ]);
        });
      });

      group('サイレントリンク', () {
        // mfm.js/test/parser.ts:1078-1087
        test('mfm-js互換テスト: silent flag', () {
          final result = parser.parse('?[Example](https://example.com)');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const LinkNode(
              silent: true,
              url: 'https://example.com',
              children: [TextNode('Example')],
            ),
          ]);
        });
      });

      group('MfmParser統合テスト', () {
        // mfm.js/test/parser.ts:1100-1106
        group('prevent xss', () {
          test('mfm-js互換テスト: javascript: URLはリンクとして解析されない', () {
            final result = parser.parse('[click here](javascript:foo)');
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [const TextNode('[click here](javascript:foo)')]);
          });
        });

        // mfm.js/test/parser.ts:1108-1145
        group('cannot nest a url in a link label', () {
          test('mfm-js互換テスト: basic', () {
            final result = parser.parse(
              'official instance: [https://misskey.io/@ai](https://misskey.io/@ai).',
            );
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [
              const TextNode('official instance: '),
              const LinkNode(
                silent: false,
                url: 'https://misskey.io/@ai',
                children: [TextNode('https://misskey.io/@ai')],
              ),
              const TextNode('.'),
            ]);
          });

          test('mfm-js互換テスト: nested', () {
            final result = parser.parse(
              'official instance: [https://misskey.io/@ai**https://misskey.io/@ai**](https://misskey.io/@ai).',
            );
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [
              const TextNode('official instance: '),
              const LinkNode(
                silent: false,
                url: 'https://misskey.io/@ai',
                children: [
                  TextNode('https://misskey.io/@ai'),
                  BoldNode([TextNode('https://misskey.io/@ai')]),
                ],
              ),
              const TextNode('.'),
            ]);
          });
        });

        // mfm.js/test/parser.ts:1147-1186
        group('cannot nest a link in a link label', () {
          test('mfm-js互換テスト: basic', () {
            final result = parser.parse(
              'official instance: [[https://misskey.io/@ai](https://misskey.io/@ai)](https://misskey.io/@ai).',
            );
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [
              const TextNode('official instance: '),
              const LinkNode(
                silent: false,
                url: 'https://misskey.io/@ai',
                children: [TextNode('[https://misskey.io/@ai')],
              ),
              const TextNode(']('),
              const UrlNode(url: 'https://misskey.io/@ai'),
              const TextNode(').'),
            ]);
          });

          test('mfm-js互換テスト: nested', () {
            final result = parser.parse(
              'official instance: [**[https://misskey.io/@ai](https://misskey.io/@ai)**](https://misskey.io/@ai).',
            );
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [
              const TextNode('official instance: '),
              const LinkNode(
                silent: false,
                url: 'https://misskey.io/@ai',
                children: [
                  BoldNode([
                    TextNode(
                      '[https://misskey.io/@ai](https://misskey.io/@ai)',
                    ),
                  ]),
                ],
              ),
              const TextNode('.'),
            ]);
          });
        });

        // mfm.js/test/parser.ts:1147-1166
        group('cannot nest a mention in a link label', () {
          test('mfm-js互換テスト: basic', () {
            final result = parser.parse('[@example](https://example.com)');
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [
              const LinkNode(
                silent: false,
                url: 'https://example.com',
                children: [TextNode('@example')],
              ),
            ]);
          });

          test('mfm-js互換テスト: nested', () {
            final result = parser.parse(
              '[@example**@example**](https://example.com)',
            );
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [
              const LinkNode(
                silent: false,
                url: 'https://example.com',
                children: [
                  TextNode('@example'),
                  BoldNode([TextNode('@example')]),
                ],
              ),
            ]);
          });
        });

        // mfm.js/test/parser.ts:1188-1227
        group('with brackets', () {
          test('mfm-js互換テスト: with brackets', () {
            final result = parser.parse('[foo](https://example.com/foo(bar))');
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [
              const LinkNode(
                silent: false,
                url: 'https://example.com/foo(bar)',
                children: [TextNode('foo')],
              ),
            ]);
          });

          test('mfm-js互換テスト: with parent brackets', () {
            final result = parser.parse(
              '([foo](https://example.com/foo(bar)))',
            );
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [
              const TextNode('('),
              const LinkNode(
                silent: false,
                url: 'https://example.com/foo(bar)',
                children: [TextNode('foo')],
              ),
              const TextNode(')'),
            ]);
          });

          test('mfm-js互換テスト: with brackets before', () {
            final result = parser.parse(
              '[test] foo [bar](https://example.com)',
            );
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [
              const TextNode('[test] foo '),
              const LinkNode(
                silent: false,
                url: 'https://example.com',
                children: [TextNode('bar')],
              ),
            ]);
          });

          test('mfm-js互換テスト: bad url in url part', () {
            final result = parser.parse('[test](http://..)');
            expect(result is Success, isTrue);
            final nodes = result.value;
            expect(nodes, [const TextNode('[test](http://..)')]);
          });
        });
      });
    });

    // mfm.js:1230-1280
    group('fn', () {
      // mfm.js/test/parser.ts:1231-1239
      test('mfm-js互換テスト: basic', () {
        final result = parser.parse(r'$[shake text]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const FnNode(name: 'shake', args: {}, children: [TextNode('text')]),
        ]);
      });

      // mfm.js/test/parser.ts:1241-1249
      test('mfm-js互換テスト: with a string argument', () {
        final result = parser.parse(r'$[flip.h content]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const FnNode(
            name: 'flip',
            args: {'h': true},
            children: [TextNode('content')],
          ),
        ]);
      });

      // mfm.js/test/parser.ts:1251-1259
      test('mfm-js互換テスト: with a string argument 2', () {
        final result = parser.parse(r'$[position.x=1.5,y=-2 text]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const FnNode(
            name: 'position',
            args: {'x': '1.5', 'y': '-2'},
            children: [TextNode('text')],
          ),
        ]);
      });

      // mfm.js/test/parser.ts:1261-1267
      test('mfm-js互換テスト: invalid fn name', () {
        final result = parser.parse(r'$[関数 text]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // fn名が無効（日本語文字）のためfnとして認識されず、テキストとして扱われる
        expect(nodes, [const TextNode(r'$[関数 text]')]);
      });

      // mfm.js/test/parser.ts:1269-1279
      test('mfm-js互換テスト: nest', () {
        final result = parser.parse(r'$[spin $[shake text]]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const FnNode(
            name: 'spin',
            args: {},
            children: [
              FnNode(
                name: 'shake',
                args: {},
                children: [TextNode('text')],
              ),
            ],
          ),
        ]);
      });
    });

    // mfm.js:1282-1302
    group('plain', () {
      // mfm.js/test/parser.ts:1283-1290
      test('mfm-js互換テスト: multiple line', () {
        final result = parser.parse(
          'a\n<plain>\n**Hello**\nworld\n</plain>\nb',
        );
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('a\n'),
          const PlainNode([TextNode('**Hello**\nworld')]),
          const TextNode('\nb'),
        ]);
      });

      // mfm.js/test/parser.ts:1293-1301
      test('mfm-js互換テスト: single line', () {
        final result = parser.parse('a\n<plain>**Hello** world</plain>\nb');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('a\n'),
          const PlainNode([TextNode('**Hello** world')]),
          const TextNode('\nb'),
        ]);
      });
    });

    // mfm.js:1304-1509
    group('nesting limit', () {
      group('quote', () {
        // mfm.js/test/parser.ts:1306-1315
        test('mfm-js互換テスト: basic', () {
          // >>> abc → 2段階目まではネスト、3段階目(> abc)はテキスト
          final parser = MfmParser().build(nestLimit: 2);
          final result = parser.parse('>>> abc');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const QuoteNode([
              QuoteNode([TextNode('> abc')]),
            ]),
          ]);
        });

        // mfm.js/test/parser.ts:1318-1327
        test('mfm-js互換テスト: basic 2', () {
          // >> **abc** → 2段階目までネスト、**abc**はテキスト
          final parser = MfmParser().build(nestLimit: 2);
          final result = parser.parse('>> **abc**');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const QuoteNode([
              QuoteNode([TextNode('**abc**')]),
            ]),
          ]);
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
          expect(nodes, [
            const BoldNode([
              BoldNode([TextNode('***abc***')]),
            ]),
          ]);
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
          expect(nodes, [
            const ItalicNode([
              ItalicNode([TextNode('**abc**')]),
            ]),
          ]);
        });

        // mfm.js/test/parser.ts:1356-1365
        test('mfm-js互換テスト: tag', () {
          // <i><i><b>abc</b></i></i> → 2段階目まではネスト、<b>abc</b>はテキスト
          final parser = MfmParser().build(nestLimit: 2);
          final result = parser.parse('<i><i><b>abc</b></i></i>');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const ItalicNode([
              ItalicNode([TextNode('<b>abc</b>')]),
            ]),
          ]);
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
          expect(nodes, [
            const ItalicNode([
              ItalicNode([TextNode('<small>abc</small>')]),
            ]),
          ]);
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
          expect(nodes, [
            const BoldNode([
              BoldNode([TextNode('<i>abc</i>')]),
            ]),
          ]);
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
          expect(nodes, [
            const BoldNode([
              BoldNode([TextNode('~~abc~~')]),
            ]),
          ]);
        });

        // mfm.js/test/parser.ts:1406-1415
        test('mfm-js互換テスト: tag', () {
          // <b><b><s>abc</s></b></b> → 2段階目まではネスト、<s>abc</s>はテキスト
          final parser = MfmParser().build(nestLimit: 2);
          final result = parser.parse('<b><b><s>abc</s></b></b>');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const BoldNode([
              BoldNode([TextNode('<s>abc</s>')]),
            ]),
          ]);
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
          expect(nodes, [
            const BoldNode([HashtagNode('abc(xyz)')]),
          ]);

          // <b>#abc(x(y)z)</b> → 二重ネスト括弧はハッシュタグとして認識されない
          result = parser.parse('<b>#abc(x(y)z)</b>');
          expect(result is Success, isTrue);
          nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const BoldNode([
              HashtagNode('abc'),
              TextNode('(x(y)z)'),
            ]),
          ]);
        });

        test('mfm-js互換テスト: outside "()"', () {
          // (#abc) → 外側の括弧はハッシュタグに含まれない
          final parser = MfmParser().build();
          final result = parser.parse('(#abc)');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const TextNode('('),
            const HashtagNode('abc'),
            const TextNode(')'),
          ]);
        });

        test('mfm-js互換テスト: outside "[]"', () {
          // [#abc] → 外側の角括弧はハッシュタグに含まれない
          final parser = MfmParser().build();
          final result = parser.parse('[#abc]');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const TextNode('['),
            const HashtagNode('abc'),
            const TextNode(']'),
          ]);
        });

        test('mfm-js互換テスト: outside "「」"', () {
          // 「#abc」 → 外側の鉤括弧はハッシュタグに含まれない
          final parser = MfmParser().build();
          final result = parser.parse('「#abc」');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const TextNode('「'),
            const HashtagNode('abc'),
            const TextNode('」'),
          ]);
        });

        test('mfm-js互換テスト: outside "（）"', () {
          // （#abc） → 外側の全角括弧はハッシュタグに含まれない
          final parser = MfmParser().build();
          final result = parser.parse('（#abc）');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const TextNode('（'),
            const HashtagNode('abc'),
            const TextNode('）'),
          ]);
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
          expect(nodes, [
            const BoldNode([
              UrlNode(url: 'https://example.com/abc(xyz)'),
            ]),
          ]);

          // <b>https://example.com/abc(x(y)z)</b> → 二重ネスト括弧はURLに含まれない
          result = parser.parse('<b>https://example.com/abc(x(y)z)</b>');
          expect(result is Success, isTrue);
          nodes = (result as Success).value as List<MfmNode>;
          expect(nodes, [
            const BoldNode([
              UrlNode(url: 'https://example.com/abc'),
              TextNode('(x(y)z)'),
            ]),
          ]);
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
          expect(nodes, [
            const BoldNode([
              BoldNode([TextNode(r'$[a b]')]),
            ]),
          ]);
        });
      });
    });

    // mfm.js:1512-1540
    group('composite', () {
      // mfm.js/test/parser.ts:1512-1538
      test('mfm.js互換: composite（大規模複合テスト）', () {
        // テキスト、中央寄せ、FN関数、メンション、URL、Unicode絵文字の複合
        const input = '''before
<center>
Hello \$[tada everynyan! 🎉]

I'm @ai, A bot of misskey!

https://github.com/syuilo/ai
</center>
after''';
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('before'),
          const CenterNode([
            TextNode('Hello '),
            FnNode(
              name: 'tada',
              args: {},
              children: [
                TextNode('everynyan! '),
                UnicodeEmojiNode('🎉'),
              ],
            ),
            TextNode("\n\nI'm "),
            MentionNode(username: 'ai', acct: '@ai'),
            TextNode(', A bot of misskey!\n\n'),
            UrlNode(url: 'https://github.com/syuilo/ai'),
          ]),
          const TextNode('after'),
        ]);
      });
    });
  });
}
