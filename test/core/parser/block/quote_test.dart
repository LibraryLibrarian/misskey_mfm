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

    test('引用内のitalic: "> *斜体*"', () {
      final m = MfmParser().build();
      final result = m.parse('> *斜体*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(
        nodes,
        [
          const QuoteNode(
            [
              ItalicNode(
                [
                  TextNode('斜体'),
                ],
              ),
            ],
          ),
        ],
      );
    });

    test('引用内の複合: "> **太字**と*斜体*"', () {
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
              TextNode('と'),
              ItalicNode(
                [
                  TextNode('斜体'),
                ],
              ),
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

    test('複数行引用内のインライン: "> **1行目**\\n> *2行目*"', () {
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
              TextNode('\n'),
              ItalicNode(
                [
                  TextNode('2行目'),
                ],
              ),
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
}
