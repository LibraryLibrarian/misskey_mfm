import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('CodeBlockParser（コードブロック）', () {
    test('基本: ```\nabc\n```', () {
      final m = MfmParser().build();
      final result = m.parse('```\nabc\n```');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<CodeBlockNode>());
      final cb = nodes[0] as CodeBlockNode;
      expect(cb.language, isNull);
      expect(cb.code, 'abc');
    });

    test('言語指定: ```js\nconst a = 1;\n```', () {
      final m = MfmParser().build();
      final result = m.parse('```js\nconst a = 1;\n```');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      final cb = nodes[0] as CodeBlockNode;
      expect(cb.language, 'js');
      expect(cb.code, 'const a = 1;');
    });

    test('言語指定（dart）: ```dart\nvoid main() {}\n```', () {
      final m = MfmParser().build();
      final result = m.parse('```dart\nvoid main() {}\n```');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      final cb = nodes[0] as CodeBlockNode;
      expect(cb.language, 'dart');
      expect(cb.code, 'void main() {}');
    });

    test('内部の ``` を無視: ```\naaa```bbb\n```', () {
      final m = MfmParser().build();
      final result = m.parse('```\naaa```bbb\n```');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      final cb = nodes[0] as CodeBlockNode;
      expect(cb.code, 'aaa```bbb');
    });

    test('コードブロックには複数行のコードを入力できる', () {
      final m = MfmParser().build();
      final result = m.parse('```\na\nb\nc\n```');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<CodeBlockNode>());
      final cb = nodes[0] as CodeBlockNode;
      expect(cb.language, isNull);
      expect(cb.code, 'a\nb\nc');
    });

    test('ブロックの前後にあるテキストが正しく解釈される', () {
      final m = MfmParser().build();
      final result = m.parse('abc\n```\nconst abc = 1;\n```\n123');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'abc');
      expect(nodes[1], isA<CodeBlockNode>());
      final cb = nodes[1] as CodeBlockNode;
      expect(cb.language, isNull);
      expect(cb.code, 'const abc = 1;');
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, '123');
    });

    test('trim after line break', () {
      final m = MfmParser().build();
      final result = m.parse('```\nfoo\n```\nbar');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect(nodes[0], isA<CodeBlockNode>());
      final cb = nodes[0] as CodeBlockNode;
      expect(cb.language, isNull);
      expect(cb.code, 'foo');
      expect(nodes[1], isA<TextNode>());
      expect((nodes[1] as TextNode).text, 'bar');
    });

    group('mfm-js互換: 行頭・行末チェック', () {
      test('行の途中から始まるコードブロックは認識されない', () {
        final m = MfmParser().build();
        final result = m.parse('text ```\ncode\n```');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // コードブロックとして認識されない（インラインコード等になる可能性がある）
        expect(nodes.any((n) => n is CodeBlockNode), isFalse);
      });

      test('行の途中で終わるコードブロックは認識されない', () {
        final m = MfmParser().build();
        final result = m.parse('```\ncode\n``` text');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // コードブロックとして認識されない（インラインコード等になる可能性がある）
        expect(nodes.any((n) => n is CodeBlockNode), isFalse);
      });

      test('正常なコードブロックは認識される（行頭・行末）', () {
        final m = MfmParser().build();
        final result = m.parse('```\ncode\n```');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<CodeBlockNode>());
      });

      test('改行の後は行頭として認識される', () {
        final m = MfmParser().build();
        final result = m.parse('text\n```\ncode\n```');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 2);
        expect(nodes[0], isA<TextNode>());
        expect(nodes[1], isA<CodeBlockNode>());
      });

      test('行末の後の改行がある場合も正常に認識される', () {
        final m = MfmParser().build();
        final result = m.parse('```\ncode\n```\n');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<CodeBlockNode>());
        final cb = nodes[0] as CodeBlockNode;
        expect(cb.code, 'code');
      });
    });
  });
}
