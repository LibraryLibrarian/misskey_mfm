import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/block/center.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('CRLF / CRブロック改行', () {
    final parser = MfmParser().build();

    void expectNodes(String input, List<MfmNode> expected) {
      final result = parser.parse(input);
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, expected);
    }

    test('CRLFのcode block境界を本文に含めない', () {
      expectNodes('```\r\ncode\r\n```', const [
        CodeBlockNode(code: 'code'),
      ]);
    });

    test('CRのcode block境界を本文に含めない', () {
      expectNodes('```\rcode\r```', const [
        CodeBlockNode(code: 'code'),
      ]);
    });

    test('mixed newlineのcode block本文を元の改行で維持する', () {
      const input = 'before\r\n```dart\r\nline1\r\nline2\nline3\r```\r\nafter';
      expectNodes(input, const [
        TextNode('before'),
        CodeBlockNode(
          code: 'line1\r\nline2\nline3',
          language: 'dart',
        ),
        TextNode('after'),
      ]);
    });

    test('CRLFのcenter境界を内容に含めない', () {
      expectNodes('<center>\r\nabc\r\n</center>', const [
        CenterNode([TextNode('abc')]),
      ]);
    });

    test('基本center parserでもCRLF境界を内容に含めない', () {
      final result = CenterParser().build().end().parse(
        '<center>\r\nabc\r\n</center>',
      );
      expect(result, isA<Success<MfmNode>>());
      expect(
        (result as Success<MfmNode>).value,
        const CenterNode([TextNode('abc')]),
      );
    });

    test('CRとmixed newlineのcenter境界・内容を区別する', () {
      const input = 'before\r<center>\r\n**abc**\ntext\r</center>\r\nafter';
      expectNodes(input, const [
        TextNode('before'),
        CenterNode([
          BoldNode([TextNode('abc')]),
          TextNode('\ntext'),
        ]),
        TextNode('after'),
      ]);
    });

    test('CRLFのmath block境界を数式に含めない', () {
      expectNodes('\\[\r\nx\r\n\\]', const [
        MathBlockNode('x'),
      ]);
    });

    test('CRLFの2行目math blockは前後の境界改行を吸収する', () {
      const input = 'before\r\n\\[\r\nx\r\n\\]\r\nafter';
      expectNodes(input, const [
        TextNode('before'),
        MathBlockNode('x'),
        TextNode('after'),
      ]);
    });

    test('CR境界を吸収し、math block内部のmixed newlineは維持する', () {
      const input = 'before\r\\[\rx\r\n+y\n\\]\rafter';
      expectNodes(input, const [
        TextNode('before'),
        MathBlockNode('x\r\n+y'),
        TextNode('after'),
      ]);
    });

    test('CRのみの複数行quoteをLFへ正規化して連結する', () {
      expectNodes('> abc\r> def', const [
        QuoteNode([TextNode('abc\ndef')]),
      ]);
    });

    test('CRLF・CR混在の複数行quoteをLFへ正規化する', () {
      const input = 'before\r\n> one\r\n> two\r> **three**\nafter';
      expectNodes(input, const [
        TextNode('before'),
        QuoteNode([
          TextNode('one\ntwo\n'),
          BoldNode([TextNode('three')]),
        ]),
        TextNode('after'),
      ]);
    });

    test('CRLF直前のsearchを解析して改行を吸収する', () {
      expectNodes('abc def search\r\nghi', const [
        SearchNode(query: 'abc def', content: 'abc def search'),
        TextNode('ghi'),
      ]);
    });

    test('CRのみの2行目searchは前後の改行を吸収する', () {
      expectNodes('before\rhoge piyo 検索\rafter', const [
        TextNode('before'),
        SearchNode(query: 'hoge piyo', content: 'hoge piyo 検索'),
        TextNode('after'),
      ]);
    });
  });

  group('CRLF / CRとインライン構文の優先順位', () {
    final parser = MfmParser().build();

    void expectNodes(String input, List<MfmNode> expected) {
      final result = parser.parse(input);
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, expected);
    }

    test('CRLF後のboldをsearchより優先する', () {
      expectNodes('before\r\n**bold** search\r\nafter', const [
        TextNode('before\r\n'),
        BoldNode([TextNode('bold')]),
        TextNode(' search\r\nafter'),
      ]);
    });

    test('CR後のURLをsearchより優先する', () {
      expectNodes('before\rhttps://example.com search\rafter', const [
        TextNode('before\r'),
        UrlNode(url: 'https://example.com'),
        TextNode(' search\rafter'),
      ]);
    });
  });

  group('CRLF / CRを禁止するインライン構文', () {
    final parser = MfmParser().build();

    void expectText(String input) {
      final result = parser.parse(input);
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, [TextNode(input)]);
    }

    test('inline codeはCRをまたがない', () {
      expectText('`foo\rbar`');
    });

    test('math inlineはCRLFをまたがない', () {
      expectText('\\(x\r\ny\\)');
    });

    test('閉じないstrikeはCRで終了し次行のboldを維持する', () {
      final result = parser.parse('~~foo\r**bar**');
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        TextNode('~~foo\r'),
        BoldNode([TextNode('bar')]),
      ]);
    });

    test('plainはCRLF境界を内容に含めない', () {
      final result = parser.parse('<plain>\r\nabc\r\n</plain>');
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        PlainNode([TextNode('abc')]),
      ]);
    });
  });
}
