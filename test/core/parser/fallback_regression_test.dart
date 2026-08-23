import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('パース失敗時のフォールバック', () {
    final parser = MfmParser().build();

    void expectNodes(String input, List<MfmNode> expected) {
      final result = parser.parse(input);
      expect(result, isA<Success<List<MfmNode>>>());
      expect((result as Success<List<MfmNode>>).value, expected);
    }

    test('snake_caseの後続にあるboldを維持する', () {
      expectNodes('snake_case_name **bold**', const [
        TextNode('snake_case_name '),
        BoldNode([TextNode('bold')]),
      ]);
    });

    test('閉じないbacktickの後続にあるboldを維持する', () {
      expectNodes("don't use ` here **bold**", const [
        TextNode("don't use ` here "),
        BoldNode([TextNode('bold')]),
      ]);
    });

    test('bold内のunderscoreをテキストとして維持する', () {
      expectNodes('**a_b** tail', const [
        BoldNode([TextNode('a_b')]),
        TextNode(' tail'),
      ]);
    });

    test('small内の閉じないbacktickをテキストとして維持する', () {
      expectNodes('<small>a`b</small> tail', const [
        SmallNode([TextNode('a`b')]),
        TextNode(' tail'),
      ]);
    });

    test('fn内のunderscoreと後続のboldを維持する', () {
      expectNodes(r'$[fg.color=f00 a_b] tail **x**', const [
        FnNode(
          name: 'fg',
          args: {'color': 'f00'},
          children: [TextNode('a_b')],
        ),
        TextNode(' tail '),
        BoldNode([TextNode('x')]),
      ]);
    });

    test('link label内のunderscoreをテキストとして維持する', () {
      expectNodes('[a_b](https://example.com)', const [
        LinkNode(
          silent: false,
          url: 'https://example.com',
          children: [TextNode('a_b')],
        ),
      ]);
    });

    test('閉じないstrikeの次行にあるboldを維持する', () {
      expectNodes('~~foo\n**bar**', const [
        TextNode('~~foo\n'),
        BoldNode([TextNode('bar')]),
      ]);
    });
  });
}
