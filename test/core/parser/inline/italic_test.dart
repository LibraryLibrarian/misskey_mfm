import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('ItalicParser（斜体構文）', () {
    final parser = ItalicParser().buildWithFallback();

    test('基本的な斜体構文を解析できる', () {
      final result = parser.parse('*italic*');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<ItalicNode>());
      final italic = node as ItalicNode;
      expect(italic.children.length, 1);
      expect(italic.children.first, isA<TextNode>());
      expect((italic.children.first as TextNode).text, 'italic');
    });

    // mfm.js: test/parser.ts:566-575 - italic alt 1 basic 2
    test('before/after: before *abc* after（MfmParser使用）', () {
      final m = MfmParser().build();
      final result = m.parse('before *abc* after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect((nodes[0] as TextNode).text, 'before ');
      expect(nodes[1], isA<ItalicNode>());
      expect(((nodes[1] as ItalicNode).children.first as TextNode).text, 'abc');
      expect((nodes[2] as TextNode).text, ' after');
    });

    test('斜体内に斜体をネストできる（最も近い閉じタグを優先）', () {
      final result = parser.parse('*a *b* c*');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<ItalicNode>());
      final italic = node as ItalicNode;
      expect(italic.children.length, 1);
      expect(italic.children.first, isA<TextNode>());
      expect((italic.children.first as TextNode).text, 'a ');
    });

    test('閉じタグがない場合はテキストとして扱う', () {
      final result = parser.parse('*abc');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<TextNode>());
      // *で始まるが閉じタグがない場合は、*以降の内容も含めてテキストとして返される
      expect((node as TextNode).text, '*abc');
    });

    test('空の斜体タグを解析できる', () {
      final result = parser.parse('**');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<ItalicNode>());
      final italic = node as ItalicNode;
      expect(italic.children.length, 0);
    });

    test('複数の斜体タグを連続で解析できる', () {
      final result = parser.parse('*italic1**italic2*');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<ItalicNode>());
      final italic = node as ItalicNode;
      expect(italic.children.length, 1);
      expect((italic.children.first as TextNode).text, 'italic1');
    });

    test('改行を含む斜体を解析できる', () {
      final result = parser.parse('*line1\nline2*');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<ItalicNode>());
      final italic = node as ItalicNode;
      expect(italic.children.length, 1);
      expect((italic.children.first as TextNode).text, 'line1\nline2');
    });

    test('単独の*はテキストとして扱う', () {
      final result = parser.parse('*');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<TextNode>());
      expect((node as TextNode).text, '*');
    });

    test('閉じタグがない場合の詳細テスト', () {
      // *で始まるが閉じタグがない場合は、*以降の内容も含めてテキストとして返される
      final testCases = [
        ('*abc', '*abc'),
        ('*abc def', '*abc def'),
        ('*', '*'),
      ];

      for (final (input, expected) in testCases) {
        final result = parser.parse(input);
        expect(result is Success, isTrue);
        final node = (result as Success).value as MfmNode;
        expect(node, isA<TextNode>());
        expect((node as TextNode).text, expected);
      }
    });

    test('閉じタグが途中にある場合は適切に処理される', () {
      // abc*def のような場合は解析失敗（*で始まらないため）
      final result = parser.parse('abc*def');
      expect(result is Failure, isTrue);
    });
  });

  group('ItalicParser（斜体構文: <i>タグ）', () {
    final tagParser = ItalicParser().buildTag();

    test('基本: <i>italic</i>', () {
      final result = tagParser.parse('<i>italic</i>');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<ItalicNode>());
      final italic = node as ItalicNode;
      expect(italic.children.length, 1);
      expect((italic.children.first as TextNode).text, 'italic');
    });

    test('before/after: before <i>abc</i> after（MfmParser使用）', () {
      final m = MfmParser().build();
      final result = m.parse('before <i>abc</i> after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect((nodes[0] as TextNode).text, 'before ');
      expect(nodes[1], isA<ItalicNode>());
      expect(((nodes[1] as ItalicNode).children.first as TextNode).text, 'abc');
      expect((nodes[2] as TextNode).text, ' after');
    });

    test('改行含む: <i>line1\nline2</i>', () {
      final result = tagParser.parse('<i>line1\nline2</i>');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<ItalicNode>());
      final italic = node as ItalicNode;
      expect((italic.children.first as TextNode).text, 'line1\nline2');
    });
  });

  group('ItalicParser（斜体構文: alt2 _..._）', () {
    final alt2Parser = ItalicParser().buildAlt2();

    test('基本: _italic_', () {
      final result = alt2Parser.parse('_italic_');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<ItalicNode>());
      final italic = node as ItalicNode;
      expect(italic.children.length, 1);
      expect((italic.children.first as TextNode).text, 'italic');
    });

    test('before/after: before _abc_ after（MfmParser使用）', () {
      final m = MfmParser().build();
      final result = m.parse('before _abc_ after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect((nodes[0] as TextNode).text, 'before ');
      expect(nodes[1], isA<ItalicNode>());
      expect(((nodes[1] as ItalicNode).children.first as TextNode).text, 'abc');
      expect((nodes[2] as TextNode).text, ' after');
    });

    test('改行含む: _line1\nline2_', () {
      final result = alt2Parser.parse('_line1\nline2_');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<ItalicNode>());
      final italic = node as ItalicNode;
      expect((italic.children.first as TextNode).text, 'line1\nline2');
    });
  });

  group('ItalicParser（直前文字ルール: * / _）', () {
    test('直前が英数字のときは * を無視する', () {
      final m = MfmParser().build();
      final result = m.parse('before*abc*after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'before*abc*after');
    });

    test('直前が英数字のときは _ を無視する', () {
      final m = MfmParser().build();
      final result = m.parse('before_abc_after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'before_abc_after');
    });

    test('日本語の直後では * を許可する', () {
      final m = MfmParser().build();
      final result = m.parse('あいう*abc*えお');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect((nodes[0] as TextNode).text, 'あいう');
      expect(nodes[1], isA<ItalicNode>());
      expect(((nodes[1] as ItalicNode).children.first as TextNode).text, 'abc');
      expect((nodes[2] as TextNode).text, 'えお');
    });

    test('日本語の直後では _ を許可する', () {
      final m = MfmParser().build();
      final result = m.parse('あいう_abc_えお');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect((nodes[0] as TextNode).text, 'あいう');
      expect(nodes[1], isA<ItalicNode>());
      expect(((nodes[1] as ItalicNode).children.first as TextNode).text, 'abc');
      expect((nodes[2] as TextNode).text, 'えお');
    });
  });

  group('ItalicParser（<i>タグ内でインライン許可）', () {
    test('太字を含められる: <i>abc**123**abc</i>', () {
      final m = MfmParser().build();
      final result = m.parse('<i>abc**123**abc</i>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      final italic = nodes[0] as ItalicNode;
      expect(italic.children.length, 3);
      expect((italic.children[0] as TextNode).text, 'abc');
      expect(italic.children[1], isA<BoldNode>());
      expect(
        ((italic.children[1] as BoldNode).children.first as TextNode).text,
        '123',
      );
      expect((italic.children[2] as TextNode).text, 'abc');
    });

    test('改行込みで太字を含められる', () {
      final m = MfmParser().build();
      final result = m.parse('<i>abc\n**123**\nabc</i>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      final italic = nodes[0] as ItalicNode;
      expect(italic.children.length, 3);
      expect((italic.children[0] as TextNode).text, 'abc\n');
      expect(italic.children[1], isA<BoldNode>());
      expect(
        ((italic.children[1] as BoldNode).children.first as TextNode).text,
        '123',
      );
      expect((italic.children[2] as TextNode).text, '\nabc');
    });
  });
}
