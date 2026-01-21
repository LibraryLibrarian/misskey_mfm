import 'package:misskey_mfm_parser/core/ast.dart';
import 'package:misskey_mfm_parser/core/parser/inline/url.dart';
import 'package:misskey_mfm_parser/core/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  final fullParser = MfmParser().build();

  /// ヘルパー: フルパーサーの結果から最初のUrlNodeを取得
  UrlNode? getFirstUrl(Result<List<MfmNode>> result) {
    if (result is! Success) return null;
    final nodes = result.value;
    for (final node in nodes) {
      if (node is UrlNode) return node;
    }
    return null;
  }

  group('UrlParser', () {
    group('生URL（フルパーサー経由）', () {
      test('基本的なHTTP URL', () {
        final result = fullParser.parse('http://example.com');
        expect(result is Success, isTrue);
        final node = getFirstUrl(result);
        expect(node, isNotNull);
        expect(node!.url, equals('http://example.com'));
        expect(node.brackets, isFalse);
      });

      test('パス付きURL', () {
        final result = fullParser.parse('https://example.com/path/to/page');
        expect(result is Success, isTrue);
        final node = getFirstUrl(result);
        expect(node, isNotNull);
        expect(node!.url, equals('https://example.com/path/to/page'));
      });

      test('クエリパラメータ付きURL', () {
        final result = fullParser.parse(
          'https://example.com/search?q=test&lang=ja',
        );
        expect(result is Success, isTrue);
        final node = getFirstUrl(result);
        expect(node, isNotNull);
        expect(node!.url, equals('https://example.com/search?q=test&lang=ja'));
      });

      test('フラグメント付きURL', () {
        final result = fullParser.parse('https://example.com/page#section');
        expect(result is Success, isTrue);
        final node = getFirstUrl(result);
        expect(node, isNotNull);
        expect(node!.url, equals('https://example.com/page#section'));
      });

      test('ポート番号付きURL', () {
        final result = fullParser.parse('https://example.com:8080/path');
        expect(result is Success, isTrue);
        final node = getFirstUrl(result);
        expect(node, isNotNull);
        expect(node!.url, equals('https://example.com:8080/path'));
      });

      test('認証情報付きURL', () {
        final result = fullParser.parse('https://user:pass@example.com/path');
        expect(result is Success, isTrue);
        final node = getFirstUrl(result);
        expect(node, isNotNull);
        expect(node!.url, equals('https://user:pass@example.com/path'));
      });

      group('括弧のネスト処理', () {
        test('丸括弧を含むURL', () {
          final result = fullParser.parse(
            'https://example.com/wiki/Test_(programming)',
          );
          expect(result is Success, isTrue);
          final node = getFirstUrl(result);
          expect(node, isNotNull);
          expect(
            node!.url,
            equals('https://example.com/wiki/Test_(programming)'),
          );
        });

        test('角括弧を含むURL', () {
          final result = fullParser.parse('https://example.com/path[1]');
          expect(result is Success, isTrue);
          final node = getFirstUrl(result);
          expect(node, isNotNull);
          expect(node!.url, equals('https://example.com/path[1]'));
        });

        test('ネストした括弧を含むURL', () {
          final result = fullParser.parse(
            'https://example.com/wiki/Test_(foo_(bar))',
          );
          expect(result is Success, isTrue);
          final node = getFirstUrl(result);
          expect(node, isNotNull);
          expect(
            node!.url,
            equals('https://example.com/wiki/Test_(foo_(bar))'),
          );
        });

        test('閉じ括弧がない場合は括弧で終了', () {
          final result = fullParser.parse('https://example.com/(test');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes.length, 2);
          expect(nodes[0], isA<UrlNode>());
          expect((nodes[0] as UrlNode).url, equals('https://example.com/'));
          expect(nodes[1], isA<TextNode>());
          expect((nodes[1] as TextNode).text, equals('(test'));
        });
      });

      group('末尾の無効文字除去', () {
        test('パス内のピリオドは保持', () {
          final result = fullParser.parse('https://example.com/file.html');
          expect(result is Success, isTrue);
          final node = getFirstUrl(result);
          expect(node, isNotNull);
          expect(node!.url, equals('https://example.com/file.html'));
        });
      });

      group('無効なケース', () {
        test('スキーマがない場合はテキスト', () {
          final result = fullParser.parse('example.com');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes.length, 1);
          expect(nodes[0], isA<TextNode>());
        });

        test('ftp:// はテキスト', () {
          final result = fullParser.parse('ftp://example.com');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes.length, 1);
          expect(nodes[0], isA<TextNode>());
        });

        test('スキーマのみはテキスト', () {
          final result = fullParser.parse('https://');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes.length, 1);
          expect(nodes[0], isA<TextNode>());
        });
      });
    });

    group('ブラケット付きURL（buildAlt）', () {
      final parser = UrlParser().buildAlt();

      test('基本的なブラケット付きURL', () {
        final result = parser.parse('<https://example.com>');
        expect(result is Success, isTrue);
        final node = result.value as UrlNode;
        expect(node.url, equals('https://example.com'));
        expect(node.brackets, isTrue);
      });

      test('HTTP URL', () {
        final result = parser.parse('<http://example.com>');
        expect(result is Success, isTrue);
        final node = result.value as UrlNode;
        expect(node.url, equals('http://example.com'));
        expect(node.brackets, isTrue);
      });

      test('パス付きURL', () {
        final result = parser.parse('<https://example.com/path/to/page>');
        expect(result is Success, isTrue);
        final node = result.value as UrlNode;
        expect(node.url, equals('https://example.com/path/to/page'));
        expect(node.brackets, isTrue);
      });

      test('特殊文字を含むURL', () {
        final result = parser.parse('<https://example.com/@user>');
        expect(result is Success, isTrue);
        final node = result.value as UrlNode;
        expect(node.url, equals('https://example.com/@user'));
        expect(node.brackets, isTrue);
      });

      test('末尾のピリオド・カンマも含まれる（生URLと異なる）', () {
        final result = parser.parse('<https://example.com/path.>');
        expect(result is Success, isTrue);
        final node = result.value as UrlNode;
        expect(node.url, equals('https://example.com/path.'));
        expect(node.brackets, isTrue);
      });

      group('無効なケース', () {
        test('閉じ括弧がない場合は失敗', () {
          final result = parser.parse('<https://example.com');
          expect(result is Failure, isTrue);
        });

        test('開き括弧がない場合は失敗', () {
          final result = parser.parse('https://example.com>');
          expect(result is Failure, isTrue);
        });

        test('スペースを含む場合は失敗', () {
          final result = parser.parse('<https://example.com/path with space>');
          expect(result is Failure, isTrue);
        });

        test('改行を含む場合は失敗', () {
          final result = parser.parse('<https://example.com/\npath>');
          expect(result is Failure, isTrue);
        });

        test('スキーマがない場合は失敗', () {
          final result = parser.parse('<example.com>');
          expect(result is Failure, isTrue);
        });
      });
    });

    group('フォールバック付きパーサー（フルパーサー経由）', () {
      test('有効なURLはUrlNodeとして解析', () {
        final result = fullParser.parse('https://example.com');
        expect(result is Success, isTrue);
        final node = getFirstUrl(result);
        expect(node, isNotNull);
      });

      test('スキーマのみの場合はTextNodeとしてフォールバック', () {
        final result = fullParser.parse('https://');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, equals('https://'));
      });

      test('http://のみの場合もTextNodeとしてフォールバック', () {
        final result = fullParser.parse('http://');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, equals('http://'));
      });
    });
  });
}
