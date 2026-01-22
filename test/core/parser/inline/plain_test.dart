import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('PlainParser（plain タグ）', () {
    test('基本: <plain>abc</plain>', () {
      final m = MfmParser().build();
      final result = m.parse('<plain>abc</plain>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const PlainNode([TextNode('abc')]),
      ]);
    });

    test('MFM構文がパースされない: <plain>**not bold**</plain>', () {
      final m = MfmParser().build();
      final result = m.parse('<plain>**not bold**</plain>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // **not bold** がそのままテキストとして保持される
      expect(nodes, [
        const PlainNode([TextNode('**not bold**')]),
      ]);
    });

    test('改行を含む: <plain>line1\nline2</plain>', () {
      final m = MfmParser().build();
      final result = m.parse('<plain>line1\nline2</plain>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const PlainNode([TextNode('line1\nline2')]),
      ]);
    });

    test('絵文字コードがパースされない: <plain>:emoji:</plain>', () {
      final m = MfmParser().build();
      final result = m.parse('<plain>:emoji:</plain>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const PlainNode([TextNode(':emoji:')]),
      ]);
    });

    test('複合テキスト: abc<plain>123</plain>xyz', () {
      final m = MfmParser().build();
      final result = m.parse('abc<plain>123</plain>xyz');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('abc'),
        const PlainNode([TextNode('123')]),
        const TextNode('xyz'),
      ]);
    });
  });
}
