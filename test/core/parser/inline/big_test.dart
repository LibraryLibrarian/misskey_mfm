import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/inline/big.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('BigParser（big構文 ***...***）', () {
    final parser = BigParser().buildWithFallback();

    test('閉じタグがない場合はテキストとして扱う', () {
      final result = parser.parse('***abc');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const TextNode('***abc'));
    });

    test('空のbig構文を解析できる', () {
      final result = parser.parse('******');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(
        node,
        const FnNode(
          name: 'tada',
          args: {},
          children: [],
        ),
      );
    });

    test('改行を含むbig構文を解析できる', () {
      final result = parser.parse('***line1\nline2***');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(
        node,
        const FnNode(
          name: 'tada',
          args: {},
          children: [TextNode('line1\nline2')],
        ),
      );
    });

    test('単独の***はテキストとして扱う', () {
      final result = parser.parse('***');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const TextNode('***'));
    });
  });

  group('BigParser統合テスト（MfmParser経由）', () {
    final mfmParser = MfmParser().build();

    test('基本的なbig構文を解析できる', () {
      final result = mfmParser.parse('***abc***');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(
        nodes,
        [
          const FnNode(
            name: 'tada',
            args: {},
            children: [TextNode('abc')],
          ),
        ],
      );
    });

    test('テキストの前後にbig構文がある場合', () {
      final result = mfmParser.parse('before ***abc*** after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(
        nodes,
        [
          const TextNode('before '),
          const FnNode(
            name: 'tada',
            args: {},
            children: [TextNode('abc')],
          ),
          const TextNode(' after'),
        ],
      );
    });

    test('bigとboldが正しく区別される', () {
      // *** は big として解析されるべき
      final bigResult = mfmParser.parse('***abc***');
      expect(bigResult is Success, isTrue);
      final bigNodes = (bigResult as Success).value as List<MfmNode>;
      expect(
        bigNodes,
        [
          const FnNode(
            name: 'tada',
            args: {},
            children: [TextNode('abc')],
          ),
        ],
      );

      // ** は bold として解析されるべき
      final boldResult = mfmParser.parse('**abc**');
      expect(boldResult is Success, isTrue);
      final boldNodes = (boldResult as Success).value as List<MfmNode>;
      expect(boldNodes, [
        const BoldNode([TextNode('abc')]),
      ]);
    });
  });
}
