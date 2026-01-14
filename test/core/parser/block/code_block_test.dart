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
  });
}
