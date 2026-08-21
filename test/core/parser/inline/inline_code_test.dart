import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/inline/inline_code.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('InlineCodeParser（インラインコード）', () {
    final parser = InlineCodeParser();
    final fullParser = MfmParser().build();

    test('連続する2つのbacktickは基本パーサーで失敗する', () {
      expect(parser.build().parse('``'), isA<Failure>());
    });

    test('空のinline codeはmarker 1文字だけTextへfallbackする', () {
      final result = parser.buildWithFallback().parse('``');
      expect(result, isA<Success<MfmNode>>());
      expect((result as Success<MfmNode>).value, const TextNode('`'));
      expect(result.position, 1);
    });

    test('full parserは空のinline code全体を隣接Textへmergeする', () {
      final result = fullParser.parse('``');
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        TextNode('``'),
      ]);
    });

    test('空白1文字のinline codeは有効', () {
      final result = fullParser.parse('` `');
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        InlineCodeNode(' '),
      ]);
    });

    test('通常のinline codeは基本パーサーでも有効', () {
      final result = parser.build().end().parse('`code`');
      expect(result, isA<Success<MfmNode>>());
      expect((result as Success<MfmNode>).value, const InlineCodeNode('code'));
    });

    test('通常のinline codeは引き続き有効', () {
      final result = fullParser.parse('before `code` after');
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        TextNode('before '),
        InlineCodeNode('code'),
        TextNode(' after'),
      ]);
    });

    test('空のinline codeの後でもboldを解析する', () {
      final result = fullParser.parse('``**bold**');
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, const [
        TextNode('``'),
        BoldNode([TextNode('bold')]),
      ]);
    });
  });
}
