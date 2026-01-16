import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('BigParser（big構文 ***...***）', () {
    final parser = BigParser().buildWithFallback();

    test('基本的なbig構文を解析できる', () {
      final result = parser.parse('***abc***');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<FnNode>());
      final fn = node as FnNode;
      expect(fn.name, 'tada');
      expect(fn.args, isEmpty);
      expect(fn.children.length, 1);
      expect(fn.children.first, isA<TextNode>());
      expect((fn.children.first as TextNode).text, 'abc');
    });

    test('閉じタグがない場合はテキストとして扱う', () {
      final result = parser.parse('***abc');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<TextNode>());
      expect((node as TextNode).text, '***abc');
    });

    test('空のbig構文を解析できる', () {
      final result = parser.parse('******');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<FnNode>());
      final fn = node as FnNode;
      expect(fn.name, 'tada');
      expect(fn.children.length, 0);
    });

    test('改行を含むbig構文を解析できる', () {
      final result = parser.parse('***line1\nline2***');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<FnNode>());
      final fn = node as FnNode;
      expect(fn.children.length, 1);
      expect((fn.children.first as TextNode).text, 'line1\nline2');
    });

    test('単独の***はテキストとして扱う', () {
      final result = parser.parse('***');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<TextNode>());
      expect((node as TextNode).text, '***');
    });
  });

  group('BigParser統合テスト（MfmParser経由）', () {
    final mfmParser = MfmParser().build();

    test('基本的なbig構文を解析できる', () {
      final result = mfmParser.parse('***abc***');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'tada');
      expect(fn.args, isEmpty);
      expect(fn.children.length, 1);
      expect((fn.children.first as TextNode).text, 'abc');
    });

    test('内容にはインライン構文を利用できる', () {
      final result = mfmParser.parse('***123**abc**123***');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'tada');
      expect(fn.children.length, 3);
      expect((fn.children[0] as TextNode).text, '123');
      expect(fn.children[1], isA<BoldNode>());
      final bold = fn.children[1] as BoldNode;
      expect(bold.children.length, 1);
      expect((bold.children.first as TextNode).text, 'abc');
      expect((fn.children[2] as TextNode).text, '123');
    });

    test('内容は改行できる', () {
      final result = mfmParser.parse('***123\n**abc**\n123***');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'tada');
      expect(fn.children.length, 3);
      expect((fn.children[0] as TextNode).text, '123\n');
      expect(fn.children[1], isA<BoldNode>());
      final bold = fn.children[1] as BoldNode;
      expect(bold.children.length, 1);
      expect((bold.children.first as TextNode).text, 'abc');
      expect((fn.children[2] as TextNode).text, '\n123');
    });

    test('テキストの前後にbig構文がある場合', () {
      final result = mfmParser.parse('before ***abc*** after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect((nodes[0] as TextNode).text, 'before ');
      expect(nodes[1], isA<FnNode>());
      final fn = nodes[1] as FnNode;
      expect(fn.name, 'tada');
      expect((fn.children.first as TextNode).text, 'abc');
      expect((nodes[2] as TextNode).text, ' after');
    });

    test('bigとboldが正しく区別される', () {
      // *** は big として解析されるべき
      final bigResult = mfmParser.parse('***abc***');
      expect(bigResult is Success, isTrue);
      final bigNodes = (bigResult as Success).value as List<MfmNode>;
      expect(bigNodes[0], isA<FnNode>());

      // ** は bold として解析されるべき
      final boldResult = mfmParser.parse('**abc**');
      expect(boldResult is Success, isTrue);
      final boldNodes = (boldResult as Success).value as List<MfmNode>;
      expect(boldNodes[0], isA<BoldNode>());
    });
  });
}
