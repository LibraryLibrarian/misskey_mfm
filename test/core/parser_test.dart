import 'package:test/test.dart';
import 'package:petitparser/petitparser.dart';
import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';

void main() {
  group('MfmParser（最小限：テキストと太字）', () {
    final parser = MfmParser().build();

    test('基本的な太字構文を解析できる', () {
      final result = parser.parse('**bold**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes.first, isA<BoldNode>());
      final bold = nodes.first as BoldNode;
      expect(bold.children.length, 1);
      expect(bold.children.first, isA<TextNode>());
      expect((bold.children.first as TextNode).text, 'bold');
    });

    test('テキストと太字の連結を解析できる', () {
      final result = parser.parse('foo**bar**baz');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'foo');
      expect(nodes[1], isA<BoldNode>());
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, 'baz');
    });

    test('太字内に太字をネストできる（最も近い閉じタグを優先）', () {
      final result = parser.parse('**a **b** c**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);

      // '**a **' -> Bold('a ')
      expect(nodes[0], isA<BoldNode>());
      final firstBold = nodes[0] as BoldNode;
      expect(firstBold.children.length, 1);
      expect(firstBold.children.first, isA<TextNode>());
      expect((firstBold.children.first as TextNode).text, 'a ');

      // 'b' -> Text
      expect(nodes[1], isA<TextNode>());
      expect((nodes[1] as TextNode).text, 'b');

      // '** c**' -> Bold(' c')
      expect(nodes[2], isA<BoldNode>());
      final lastBold = nodes[2] as BoldNode;
      expect(lastBold.children.length, 1);
      expect((lastBold.children.first as TextNode).text, ' c');
    });

    test('閉じタグがない場合はテキストとして扱う', () {
      final result = parser.parse('**abc');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, '**abc');
    });

    test('空の太字タグを解析できる', () {
      final result = parser.parse('****');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<BoldNode>());
      final bold = nodes[0] as BoldNode;
      expect(bold.children.length, 0);
    });

    test('複数の太字タグを連続で解析できる', () {
      final result = parser.parse('**bold1****bold2**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect(nodes[0], isA<BoldNode>());
      expect(nodes[1], isA<BoldNode>());

      final firstBold = nodes[0] as BoldNode;
      expect(firstBold.children.length, 1);
      expect((firstBold.children.first as TextNode).text, 'bold1');

      final secondBold = nodes[1] as BoldNode;
      expect(secondBold.children.length, 1);
      expect((secondBold.children.first as TextNode).text, 'bold2');
    });

    test('改行を含む太字を解析できる', () {
      final result = parser.parse('**line1\nline2**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<BoldNode>());
      final bold = nodes[0] as BoldNode;
      expect(bold.children.length, 1);
      expect((bold.children.first as TextNode).text, 'line1\nline2');
    });

    test('単独の**はテキストとして扱う', () {
      final result = parser.parse('**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, '**');
    });
  });
}
