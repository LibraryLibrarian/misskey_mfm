import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('QuoteParser（引用: インライン構文対応）', () {
    test('引用内のbold: "> **太字**"', () {
      final m = MfmParser().build();
      final result = m.parse('> **太字**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(
        nodes,
        [
          const QuoteNode(
            [
              BoldNode(
                [
                  TextNode('太字'),
                ],
              ),
            ],
          ),
        ],
      );
    });

    test('引用内のASCII英数字以外を含むitalicはテキストとして扱う', () {
      final m = MfmParser().build();
      final result = m.parse('> *斜体*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(
        nodes,
        [
          const QuoteNode(
            [
              TextNode('*斜体*'),
            ],
          ),
        ],
      );
    });

    test('引用内の複合: ASCII英数字以外を含むitalicはテキストになる', () {
      final m = MfmParser().build();
      final result = m.parse('> **太字**と*斜体*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(
        nodes,
        [
          const QuoteNode(
            [
              BoldNode(
                [
                  TextNode('太字'),
                ],
              ),
              TextNode('と*斜体*'),
            ],
          ),
        ],
      );
    });

    test('引用内のインラインコード: "> `code`"', () {
      final m = MfmParser().build();
      final result = m.parse('> `code`');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(
        nodes,
        [
          const QuoteNode(
            [
              InlineCodeNode('code'),
            ],
          ),
        ],
      );
    });

    test('複数行引用内のASCII英数字以外を含むitalicはテキストになる', () {
      final m = MfmParser().build();
      final result = m.parse('> **1行目**\n> *2行目*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(
        nodes,
        [
          const QuoteNode(
            [
              BoldNode(
                [
                  TextNode('1行目'),
                ],
              ),
              TextNode('\n*2行目*'),
            ],
          ),
        ],
      );
    });
  });

  group('QuoteParser（スペースなし引用）', () {
    test('スペースなし: ">abc"', () {
      final m = MfmParser().build();
      final result = m.parse('>abc');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(
        nodes,
        [
          const QuoteNode(
            [
              TextNode('abc'),
            ],
          ),
        ],
      );
    });
  });

  group('QuoteParser（mfm.js互換性）', () {
    test('`>` の直後のタブを1文字だけ取り除く', () {
      final result = MfmParser().build().parse('>\tfoo');

      expect(result, isA<Success<List<MfmNode>>>());
      expect(
        (result as Success<List<MfmNode>>).value,
        const [
          QuoteNode([TextNode('foo')]),
        ],
      );
    });

    test('`>` の直後の全角スペースを1文字だけ取り除く', () {
      final result = MfmParser().build().parse('>　foo');

      expect(result, isA<Success<List<MfmNode>>>());
      expect(
        (result as Success<List<MfmNode>>).value,
        const [
          QuoteNode([TextNode('foo')]),
        ],
      );
    });

    test('内容が空の引用が複数行ある場合はquoteとして解析する', () {
      final result = MfmParser().build().parse('>\n>\n>');

      expect(result, isA<Success<List<MfmNode>>>());
      expect(
        (result as Success<List<MfmNode>>).value,
        const [
          QuoteNode([TextNode('\n\n')]),
        ],
      );
    });

    for (final input in ['>', '> ']) {
      test('内容が空の引用1行だけはquoteとして解析しない: `$input`', () {
        final result = MfmParser().build().parse(input);

        expect(result, isA<Success<List<MfmNode>>>());
        expect(
          (result as Success<List<MfmNode>>).value,
          [TextNode(input)],
        );
      });
    }

    test('内容がある複数行引用は引き続きquoteとして解析する', () {
      final result = MfmParser().build().parse('> first\n> second');

      expect(result, isA<Success<List<MfmNode>>>());
      expect(
        (result as Success<List<MfmNode>>).value,
        const [
          QuoteNode([TextNode('first\nsecond')]),
        ],
      );
    });

    test('行の途中の `>` はquoteとして解析しない', () {
      final result = MfmParser().build().parse('**bold**> quote');

      expect(result, isA<Success<List<MfmNode>>>());
      expect(
        (result as Success<List<MfmNode>>).value,
        const [
          BoldNode([TextNode('bold')]),
          TextNode('> quote'),
        ],
      );
    });
  });
}
