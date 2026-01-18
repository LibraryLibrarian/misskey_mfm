import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('MathBlockParser（数式ブロック）', () {
    test(r'基本: \[math1\]', () {
      final m = MfmParser().build();
      final result = m.parse(r'\[math1\]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<MathBlockNode>());
      final math = nodes[0] as MathBlockNode;
      expect(math.formula, 'math1');
    });

    test(r'複数行: \[\na = 2\n\]', () {
      final m = MfmParser().build();
      final result = m.parse('\\[\na = 2\n\\]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<MathBlockNode>());
      final math = nodes[0] as MathBlockNode;
      expect(math.formula, 'a = 2');
    });

    test(r'複雑な数式: \[x = {-b \pm \sqrt{b^2-4ac} \over 2a}\]', () {
      final m = MfmParser().build();
      final result = m.parse(r'\[x = {-b \pm \sqrt{b^2-4ac} \over 2a}\]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<MathBlockNode>());
      final math = nodes[0] as MathBlockNode;
      expect(math.formula, r'x = {-b \pm \sqrt{b^2-4ac} \over 2a}');
    });

    test('前後にテキスト: abc\n\\[math\\]\nxyz', () {
      final m = MfmParser().build();
      final result = m.parse('abc\n\\[math\\]\nxyz');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // abc\n, mathBlock, \nxyz の3つ
      expect(nodes.any((n) => n is MathBlockNode), isTrue);
    });

    // mfm-js互換テスト: line position
    test(r'行末以外に閉じタグがある場合はマッチしない: \[aaa\]after', () {
      final m = MfmParser().build();
      final result = m.parse(r'\[aaa\]after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // MathBlockとしてパースされず、プレーンテキストとして扱われる
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, r'\[aaa\]after');
    });

    test(r'行頭以外に開始タグがある場合はマッチしない: before\[aaa\]', () {
      final m = MfmParser().build();
      final result = m.parse(r'before\[aaa\]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // MathBlockとしてパースされず、プレーンテキストとして扱われる
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, r'before\[aaa\]');
    });
  });
}
