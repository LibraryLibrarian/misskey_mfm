import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/inline/italic.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('ItalicParser（斜体構文）', () {
    final parser = ItalicParser().buildWithFallback();

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

    test('改行含む: _line1\nline2_', () {
      final result = alt2Parser.parse('_line1\nline2_');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<ItalicNode>());
      final italic = node as ItalicNode;
      expect((italic.children.first as TextNode).text, 'line1\nline2');
    });
  });

  group('ItalicParser（<i>タグ内でインライン許可）', () {});
}
