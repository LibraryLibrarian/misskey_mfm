import 'package:test/test.dart';
import 'package:petitparser/petitparser.dart';
import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';

void main() {
  group('BoldParser（太字構文）', () {
    final parser = BoldParser().buildWithFallback();

    test('基本的な太字構文を解析できる', () {
      final result = parser.parse('**bold**');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<BoldNode>());
      final bold = node as BoldNode;
      expect(bold.children.length, 1);
      expect(bold.children.first, isA<TextNode>());
      expect((bold.children.first as TextNode).text, 'bold');
    });

    test('太字内に太字をネストできる（最も近い閉じタグを優先）', () {
      final result = parser.parse('**a **b** c**');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<BoldNode>());
      final bold = node as BoldNode;
      expect(bold.children.length, 1);
      expect(bold.children.first, isA<TextNode>());
      expect((bold.children.first as TextNode).text, 'a ');
    });

    test('閉じタグがない場合はテキストとして扱う', () {
      final result = parser.parse('**abc');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<TextNode>());
      // **で始まるが閉じタグがない場合は、**以降の内容も含めてテキストとして返される
      expect((node as TextNode).text, '**abc');
    });

    test('空の太字タグを解析できる', () {
      final result = parser.parse('****');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<BoldNode>());
      final bold = node as BoldNode;
      expect(bold.children.length, 0);
    });

    test('複数の太字タグを連続で解析できる', () {
      final result = parser.parse('**bold1****bold2**');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<BoldNode>());
      final bold = node as BoldNode;
      expect(bold.children.length, 1);
      expect((bold.children.first as TextNode).text, 'bold1');
    });

    test('改行を含む太字を解析できる', () {
      final result = parser.parse('**line1\nline2**');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<BoldNode>());
      final bold = node as BoldNode;
      expect(bold.children.length, 1);
      expect((bold.children.first as TextNode).text, 'line1\nline2');
    });

    test('単独の**はテキストとして扱う', () {
      final result = parser.parse('**');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<TextNode>());
      expect((node as TextNode).text, '**');
    });

    test('閉じタグがない場合の詳細テスト', () {
      // **で始まるが閉じタグがない場合は、**以降の内容も含めてテキストとして返される
      final testCases = [
        ('**abc', '**abc'),
        ('**abc def', '**abc def'),
        ('**', '**'),
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
      // abc**def のような場合は解析失敗（**で始まらないため）
      final result = parser.parse('abc**def');
      expect(result is Failure, isTrue);
    });
  });
}
