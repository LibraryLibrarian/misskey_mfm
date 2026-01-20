import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('SearchParser（検索ブロック）', () {
    // mfm.js/test/parser.ts:187-193
    test('mfm-js互換テスト: Search', () {
      final m = MfmParser().build();
      final result = m.parse('MFM 書き方 123 Search');
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
      final m = MfmParser().build();
      final result = m.parse('MFM 書き方 123 [Search]');
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
      final m = MfmParser().build();
      final result = m.parse('MFM 書き方 検索');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<SearchNode>());
      final search = nodes[0] as SearchNode;
      expect(search.query, 'MFM 書き方');
      expect(search.content, 'MFM 書き方 検索');
    });

    // mfm.js/test/parser.ts:201-207
    test('mfm-js互換テスト: search', () {
      final m = MfmParser().build();
      final result = m.parse('MFM 書き方 123 search');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<SearchNode>());
      final search = nodes[0] as SearchNode;
      expect(search.query, 'MFM 書き方 123');
    });

    // mfm.js/test/parser.ts:208-214
    test('mfm-js互換テスト: [search]', () {
      final m = MfmParser().build();
      final result = m.parse('MFM 書き方 123 [search]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<SearchNode>());
      final search = nodes[0] as SearchNode;
      expect(search.query, 'MFM 書き方 123');
      expect(search.content, 'MFM 書き方 123 [search]');
    });

    // mfm.js/test/parser.ts:222-228
    test('mfm-js互換テスト: [検索]', () {
      final m = MfmParser().build();
      final result = m.parse('MFM 書き方 [検索]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<SearchNode>());
      final search = nodes[0] as SearchNode;
      expect(search.query, 'MFM 書き方');
      expect(search.content, 'MFM 書き方 [検索]');
    });

    test('大文字混合: MFM SEARCH', () {
      final m = MfmParser().build();
      final result = m.parse('MFM SEARCH');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<SearchNode>());
      final search = nodes[0] as SearchNode;
      expect(search.query, 'MFM');
    });

    // mfm.js/test/parser.ts:230-238
    test('mfm-js互換テスト: ブロックの前後にあるテキストが正しく解釈される', () {
      final m = MfmParser().build();
      final result = m.parse('abc\nhoge piyo bebeyo 検索\n123');
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
}
