import 'package:test/test.dart';
import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';

void main() {
  group('mergeAdjacentTextNodes（共通ユーティリティ）', () {
    test('隣接するTextNodeをマージできる', () {
      final nodes = [
        TextNode('Hello'),
        TextNode(' '),
        TextNode('World'),
        BoldNode([TextNode('bold')]),
        TextNode('!'),
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
      final nodes = [TextNode('Hello'), TextNode(' '), TextNode('World')];

      final result = mergeAdjacentTextNodes(nodes);

      expect(result.length, 1);
      expect(result[0], isA<TextNode>());
      expect((result[0] as TextNode).text, 'Hello World');
    });

    test('TextNodeが混在しない場合は変更されない', () {
      final nodes = [
        BoldNode([TextNode('bold')]),
        ItalicNode([TextNode('italic')]),
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
      final nodes = [TextNode('single')];

      final result = mergeAdjacentTextNodes(nodes);

      expect(result.length, 1);
      expect(result[0], isA<TextNode>());
      expect((result[0] as TextNode).text, 'single');
    });
  });
}
