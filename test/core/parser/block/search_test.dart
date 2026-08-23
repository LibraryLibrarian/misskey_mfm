import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/block/search.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('SearchParser（検索ブロック）', () {
    test('大文字混合: MFM SEARCH', () {
      final m = MfmParser().build();
      final result = m.parse('MFM SEARCH');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [const SearchNode(query: 'MFM', content: 'MFM SEARCH')]);
    });

    test('実際の行頭から始まる検索ブロックを解析する', () {
      final result = SearchParser().build().end().parse('\nquery Search');
      expect(result is Success, isTrue);
      expect(
        (result as Success).value,
        const SearchNode(query: 'query', content: 'query Search'),
      );
    });

    test('行の途中から始まる検索らしい断片はプレーンテキストになる', () {
      const input = 'abc query Search';
      final plainText = any().plus().flatten().map<MfmNode>(TextNode.new);
      final parser = (SearchParser().build() | plainText).end();

      final result = parser.parseOn(const Context(input, 4));
      expect(result is Success, isTrue);
      expect((result as Success).value, const TextNode('query Search'));
    });
  });

  group('MfmParser（インライン構文とsearchの優先順位）', () {
    final parser = MfmParser().build();

    void expectNodes(String input, List<MfmNode> expected) {
      final result = parser.parse(input);
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, expected);
    }

    test('boldで始まる行をsearchとして扱わない', () {
      expectNodes('**bold** search', const [
        BoldNode([TextNode('bold')]),
        TextNode(' search'),
      ]);
    });

    test('inline codeで始まる行をsearchとして扱わない', () {
      expectNodes('`code` foo search', const [
        InlineCodeNode('code'),
        TextNode(' foo search'),
      ]);
    });

    test('URLで始まる行をsearchとして扱わない', () {
      expectNodes('https://example.com search', const [
        UrlNode(url: 'https://example.com'),
        TextNode(' search'),
      ]);
    });

    test('Unicode絵文字で始まる行をsearchとして扱わない', () {
      expectNodes('🎉 abc search', const [
        UnicodeEmojiNode('🎉'),
        TextNode(' abc search'),
      ]);
    });

    test('hashtagで始まる行をsearchとして扱わない', () {
      expectNodes('#tag abc search', const [
        HashtagNode('tag'),
        TextNode(' abc search'),
      ]);
    });

    test('2行目がboldで始まる場合もsearchとして扱わない', () {
      expectNodes('before\n**bold** search\nafter', const [
        TextNode('before\n'),
        BoldNode([TextNode('bold')]),
        TextNode(' search\nafter'),
      ]);
    });

    test('2行目がinline codeで始まる場合もsearchとして扱わない', () {
      expectNodes('before\n`code` foo search\nafter', const [
        TextNode('before\n'),
        InlineCodeNode('code'),
        TextNode(' foo search\nafter'),
      ]);
    });

    test('2行目がURLで始まる場合もsearchとして扱わない', () {
      expectNodes('before\nhttps://example.com search\nafter', const [
        TextNode('before\n'),
        UrlNode(url: 'https://example.com'),
        TextNode(' search\nafter'),
      ]);
    });

    test('2行目がUnicode絵文字で始まる場合もsearchとして扱わない', () {
      expectNodes('before\n🎉 abc search\nafter', const [
        TextNode('before\n'),
        UnicodeEmojiNode('🎉'),
        TextNode(' abc search\nafter'),
      ]);
    });

    test('2行目がhashtagで始まる場合もsearchとして扱わない', () {
      expectNodes('before\n#tag abc search\nafter', const [
        TextNode('before\n'),
        HashtagNode('tag'),
        TextNode(' abc search\nafter'),
      ]);
    });

    test('通常テキストで始まる正当なsearchを維持する', () {
      expectNodes('MFM 書き方 123 Search', const [
        SearchNode(
          query: 'MFM 書き方 123',
          content: 'MFM 書き方 123 Search',
        ),
      ]);
    });

    test('2行目の正当なsearchは前後の改行を吸収する', () {
      expectNodes('before\nhoge piyo 検索\nafter', const [
        TextNode('before'),
        SearchNode(
          query: 'hoge piyo',
          content: 'hoge piyo 検索',
        ),
        TextNode('after'),
      ]);
    });
  });
}
