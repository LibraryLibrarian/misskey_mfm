import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('PlainParser（plain タグ）', () {
    test('基本: <plain>abc</plain>', () {
      final m = MfmParser().build();
      final result = m.parse('<plain>abc</plain>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<PlainNode>());
      final plain = nodes[0] as PlainNode;
      expect(plain.children.length, 1);
      expect((plain.children.first as TextNode).text, 'abc');
    });

    test('MFM構文がパースされない: <plain>**not bold**</plain>', () {
      final m = MfmParser().build();
      final result = m.parse('<plain>**not bold**</plain>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<PlainNode>());
      final plain = nodes[0] as PlainNode;
      expect(plain.children.length, 1);
      // **not bold** がそのままテキストとして保持される
      expect((plain.children.first as TextNode).text, '**not bold**');
    });

    test('改行を含む: <plain>line1\nline2</plain>', () {
      final m = MfmParser().build();
      final result = m.parse('<plain>line1\nline2</plain>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<PlainNode>());
      final plain = nodes[0] as PlainNode;
      expect((plain.children.first as TextNode).text, 'line1\nline2');
    });

    test('絵文字コードがパースされない: <plain>:emoji:</plain>', () {
      final m = MfmParser().build();
      final result = m.parse('<plain>:emoji:</plain>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<PlainNode>());
      final plain = nodes[0] as PlainNode;
      expect((plain.children.first as TextNode).text, ':emoji:');
    });

    test('複合テキスト: abc<plain>123</plain>xyz', () {
      final m = MfmParser().build();
      final result = m.parse('abc<plain>123</plain>xyz');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect((nodes[0] as TextNode).text, 'abc');
      expect(nodes[1], isA<PlainNode>());
      expect((nodes[2] as TextNode).text, 'xyz');
    });

    // mfm.js/test/parser.ts:1283-1290
    test('mfm-js互換テスト: multiple line', () {
      final m = MfmParser().build();
      final result = m.parse('a\n<plain>\n**Hello**\nworld\n</plain>\nb');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect((nodes[0] as TextNode).text, 'a\n');
      expect(nodes[1], isA<PlainNode>());
      final plain = nodes[1] as PlainNode;
      expect(plain.children.length, 1);
      expect((plain.children.first as TextNode).text, '**Hello**\nworld');
      expect((nodes[2] as TextNode).text, '\nb');
    });

    // mfm.js/test/parser.ts:1293-1301
    test('mfm-js互換テスト: single line', () {
      final m = MfmParser().build();
      final result = m.parse('a\n<plain>**Hello** world</plain>\nb');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect((nodes[0] as TextNode).text, 'a\n');
      expect(nodes[1], isA<PlainNode>());
      final plain = nodes[1] as PlainNode;
      expect(plain.children.length, 1);
      expect((plain.children.first as TextNode).text, '**Hello** world');
      expect((nodes[2] as TextNode).text, '\nb');
    });
  });
}
