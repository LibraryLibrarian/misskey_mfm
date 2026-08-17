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
}
