import 'package:misskey_mfm_parser/src/ast.dart';
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
  });
}
