import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser/inline/url.dart';
import 'package:misskey_mfm/core/parser/parser.dart';
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
      // mfm.js/test/parser.ts:932-938
      test('mfm-js互換テスト: basic', () {
        final result = fullParser.parse('https://example.com');
        expect(result is Success, isTrue);
        final node = getFirstUrl(result);
        expect(node, isNotNull);
        expect(node!.url, equals('https://example.com'));
        expect(node.brackets, isFalse);
      });

      // mfm.js/test/parser.ts:940-948
      test('mfm-js互換テスト: with other texts', () {
        final result = fullParser.parse(
          'official instance: https://misskey.io/@ai.',
        );
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'official instance: ');
        expect(nodes[1], isA<UrlNode>());
        expect((nodes[1] as UrlNode).url, 'https://misskey.io/@ai');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, '.');
      });

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

      // mfm.js/test/parser.ts:976-982
      test('mfm-js互換テスト: with comma', () {
        final result = fullParser.parse('https://example.com/foo?bar=a,b');
        expect(result is Success, isTrue);
        final node = getFirstUrl(result);
        expect(node, isNotNull);
        expect(node!.url, equals('https://example.com/foo?bar=a,b'));
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
        // mfm.js/test/parser.ts:993-999
        test('mfm-js互換テスト: with brackets', () {
          final result = fullParser.parse('https://example.com/foo(bar)');
          expect(result is Success, isTrue);
          final node = getFirstUrl(result);
          expect(node, isNotNull);
          expect(node!.url, equals('https://example.com/foo(bar)'));
        });

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

      // mfm.js/test/parser.ts:950-991
      group('末尾の無効文字除去', () {
        test('mfm-js互換テスト: 末尾のピリオドを除去', () {
          final result = fullParser.parse('https://example.com.');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes.length, 2);
          expect(nodes[0], isA<UrlNode>());
          expect((nodes[0] as UrlNode).url, equals('https://example.com'));
          expect(nodes[1], isA<TextNode>());
          expect((nodes[1] as TextNode).text, equals('.'));
        });

        test('mfm-js互換テスト: 末尾のカンマを除去', () {
          final result = fullParser.parse('https://example.com,');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes.length, 2);
          expect((nodes[0] as UrlNode).url, equals('https://example.com'));
        });

        test('mfm-js互換テスト: 末尾の複数ピリオド・カンマを除去', () {
          final result = fullParser.parse('https://example.com.,.');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect((nodes[0] as UrlNode).url, equals('https://example.com'));
        });

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

  // mfm.js/test/parser.ts:931-1063
  group('mfm-js互換テスト', () {
    group('edge cases', () {
      test('mfm-js互換テスト: disallow period only', () {
        // mfm-js: https://. はURLとして認識されず、テキストとして扱われる
        final result = fullParser.parse('https://.');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, equals('https://.'));
      });
    });

    group('parent brackets handling', () {
      test('mfm-js互換テスト: ignore parent brackets', () {
        // mfm-js: 親括弧内のURLは括弧を含まない
        final result = fullParser.parse('(https://example.com/foo)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(3));
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, equals('('));
        expect(nodes[1], isA<UrlNode>());
        expect((nodes[1] as UrlNode).url, equals('https://example.com/foo'));
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, equals(')'));
      });

      test('mfm-js互換テスト: ignore parent brackets (2)', () {
        // mfm-js: テキスト後の親括弧内URLも同様
        final result = fullParser.parse('(foo https://example.com/foo)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(3));
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, equals('(foo '));
        expect(nodes[1], isA<UrlNode>());
        expect((nodes[1] as UrlNode).url, equals('https://example.com/foo'));
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, equals(')'));
      });

      test('mfm-js互換テスト: ignore parent brackets with internal brackets', () {
        // mfm-js: 内部括弧を含むURLは内部括弧を保持し、親括弧は除外
        final result = fullParser.parse('(https://example.com/foo(bar))');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(3));
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, equals('('));
        expect(nodes[1], isA<UrlNode>());
        expect(
          (nodes[1] as UrlNode).url,
          equals('https://example.com/foo(bar)'),
        );
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, equals(')'));
      });

      test('mfm-js互換テスト: ignore parent []', () {
        // mfm-js: 角括弧内のURLも同様に処理
        final result = fullParser.parse('foo [https://example.com/foo] bar');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(3));
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, equals('foo ['));
        expect(nodes[1], isA<UrlNode>());
        expect((nodes[1] as UrlNode).url, equals('https://example.com/foo'));
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, equals('] bar'));
      });
    });

    group('non-ascii and xss prevention', () {
      test(
        'mfm-js互換テスト: ignore non-ascii characters contained url without angle brackets',
        () {
          // mfm-js: 非ASCII文字を含むURLはブラケットなしではテキストとして扱う
          final result = fullParser.parse('https://大石泉すき.example.com');
          expect(result is Success, isTrue);
          final nodes = result.value;
          expect(nodes.length, equals(1));
          expect(nodes[0], isA<TextNode>());
          expect(
            (nodes[0] as TextNode).text,
            equals('https://大石泉すき.example.com'),
          );
        },
      );

      test('mfm-js互換テスト: match non-ascii characters contained url with angle brackets', () {
        // mfm-js: ブラケット付きなら非ASCII文字を含むURLも認識
        final result = fullParser.parse('<https://大石泉すき.example.com>');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        expect(nodes[0], isA<UrlNode>());
        final urlNode = nodes[0] as UrlNode;
        expect(urlNode.url, equals('https://大石泉すき.example.com'));
        expect(urlNode.brackets, isTrue);
      });

      test('mfm-js互換テスト: prevent xss', () {
        // mfm-js: javascript: スキームはURLとして認識しない（XSS防止）
        final result = fullParser.parse('javascript:foo');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, equals('javascript:foo'));
      });
    });
  });
}
