import 'package:test/test.dart';
import 'package:petitparser/petitparser.dart';
import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';

void main() {
  group('MfmParser（統合テスト）', () {
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

    test('基本的な斜体構文を解析できる', () {
      final result = parser.parse('*italic*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes.first, isA<ItalicNode>());
      final italic = nodes.first as ItalicNode;
      expect(italic.children.length, 1);
      expect(italic.children.first, isA<TextNode>());
      expect((italic.children.first as TextNode).text, 'italic');
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

    test('太字と斜体の組み合わせを解析できる', () {
      final result = parser.parse('**bold** *italic*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect(nodes[0], isA<BoldNode>());
      expect(nodes[1], isA<TextNode>());
      expect((nodes[1] as TextNode).text, ' *italic*');
    });

    test('斜体内に太字をネストできる', () {
      final result = parser.parse('*italic **bold** text*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<ItalicNode>());
      expect(nodes[1], isA<ItalicNode>());
      expect(nodes[2], isA<ItalicNode>());
    });

    test('太字内に斜体をネストできる', () {
      final result = parser.parse('**bold *italic* text**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<BoldNode>());
      final bold = nodes[0] as BoldNode;
      expect(bold.children.length, 1);
      expect((bold.children[0] as TextNode).text, 'bold *italic* text');
    });

    test('複雑なネスト構造を解析できる', () {
      final result = parser.parse('**bold *italic **nested** text* more**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<BoldNode>());
      expect(nodes[1], isA<TextNode>());
      expect(nodes[2], isA<BoldNode>());
    });

    test('プレーンテキストのみを解析できる', () {
      final result = parser.parse('plain text without formatting');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'plain text without formatting');
    });

    test('不完全な斜体構文を解析できる', () {
      final result = parser.parse('*これは斜体**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 斜体+余剰'*'テキストの2ノードになる
      expect(nodes.length, 2);
      expect(nodes[0], isA<ItalicNode>());
      expect((nodes[0] as ItalicNode).children.first, isA<TextNode>());
      expect(
        ((nodes[0] as ItalicNode).children.first as TextNode).text,
        'これは斜体',
      );
      expect(nodes[1], isA<TextNode>());
      expect((nodes[1] as TextNode).text, '*');
    });

    test('不完全な太字構文を解析できる', () {
      final result = parser.parse('**これは太字*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 閉じ'**'が無いため全体テキストとして扱われる
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, '**これは太字*');
    });

    test('複雑な不完全な構文を解析できる', () {
      final result = parser.parse('*斜体**太字**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 斜体('斜体') + 斜体('太字') + 余剰'*' の3ノード
      expect(nodes.length, 3);
      expect(nodes[0], isA<ItalicNode>());
      expect(((nodes[0] as ItalicNode).children.first as TextNode).text, '斜体');
      expect(nodes[1], isA<ItalicNode>());
      expect(((nodes[1] as ItalicNode).children.first as TextNode).text, '太字');
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, '*');
    });
  });
}
