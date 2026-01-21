import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/common/utils.dart';
import 'package:test/test.dart';

void main() {
  group('mergeAdjacentTextNodes（共通ユーティリティ）', () {
    test('隣接するTextNodeをマージできる', () {
      final nodes = [
        const TextNode('Hello'),
        const TextNode(' '),
        const TextNode('World'),
        const BoldNode([TextNode('bold')]),
        const TextNode('!'),
      ];

      final result = mergeAdjacentTextNodes(nodes);

      expect(result.length, 3);
      expect(result[0], isA<TextNode>());
      expect((result[0] as TextNode).text, 'Hello World');
      expect(result[1], isA<BoldNode>());
      expect(result[2], isA<TextNode>());
      expect((result[2] as TextNode).text, '!');
    });

    test('TextNodeのみの場合は1つにマージされる', () {
      final nodes = [
        const TextNode('Hello'),
        const TextNode(' '),
        const TextNode('World'),
      ];

      final result = mergeAdjacentTextNodes(nodes);

      expect(result.length, 1);
      expect(result[0], isA<TextNode>());
      expect((result[0] as TextNode).text, 'Hello World');
    });

    test('TextNodeが混在しない場合は変更されない', () {
      final nodes = [
        const BoldNode([TextNode('bold')]),
        const ItalicNode([TextNode('italic')]),
      ];

      final result = mergeAdjacentTextNodes(nodes);

      expect(result.length, 2);
      expect(result[0], isA<BoldNode>());
      expect(result[1], isA<ItalicNode>());
    });

    test('空のリストの場合は空のリストが返される', () {
      final nodes = <MfmNode>[];

      final result = mergeAdjacentTextNodes(nodes);

      expect(result.length, 0);
    });

    test('単一のTextNodeの場合は変更されない', () {
      final nodes = [const TextNode('single')];

      final result = mergeAdjacentTextNodes(nodes);

      expect(result.length, 1);
      expect(result[0], isA<TextNode>());
      expect((result[0] as TextNode).text, 'single');
    });
  });
}
