import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser/inline/url.dart';
import 'package:misskey_mfm/core/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('UrlParser', () {
    group('生URL（build）', () {
      final parser = UrlParser().build();

      test('基本的なHTTPS URL', () {
        final result = parser.parse('https://example.com');
        expect(result is Success, isTrue);
        final node = result.value as UrlNode;
        expect(node.url, equals('https://example.com'));
        expect(node.brackets, isFalse);
      });

      test('基本的なHTTP URL', () {
        final result = parser.parse('http://example.com');
        expect(result is Success, isTrue);
        final node = result.value as UrlNode;
        expect(node.url, equals('http://example.com'));
        expect(node.brackets, isFalse);
      });

      test('パス付きURL', () {
        final result = parser.parse('https://example.com/path/to/page');
        expect(result is Success, isTrue);
        final node = result.value as UrlNode;
        expect(node.url, equals('https://example.com/path/to/page'));
      });

      test('クエリパラメータ付きURL', () {
        final result = parser.parse(
          'https://example.com/search?q=test&lang=ja',
        );
        expect(result is Success, isTrue);
        final node = result.value as UrlNode;
        expect(node.url, equals('https://example.com/search?q=test&lang=ja'));
      });

      test('フラグメント付きURL', () {
        final result = parser.parse('https://example.com/page#section');
        expect(result is Success, isTrue);
        final node = result.value as UrlNode;
        expect(node.url, equals('https://example.com/page#section'));
      });

      test('ポート番号付きURL', () {
        final result = parser.parse('https://example.com:8080/path');
        expect(result is Success, isTrue);
        final node = result.value as UrlNode;
        expect(node.url, equals('https://example.com:8080/path'));
      });

      test('認証情報付きURL', () {
        final result = parser.parse('https://user:pass@example.com/path');
        expect(result is Success, isTrue);
        final node = result.value as UrlNode;
        expect(node.url, equals('https://user:pass@example.com/path'));
      });

      group('括弧のネスト処理', () {
        test('丸括弧を含むURL', () {
          final result = parser.parse(
            'https://example.com/wiki/Test_(programming)',
          );
          expect(result is Success, isTrue);
          final node = result.value as UrlNode;
          expect(
            node.url,
            equals('https://example.com/wiki/Test_(programming)'),
          );
        });

        test('角括弧を含むURL', () {
          final result = parser.parse('https://example.com/path[1]');
          expect(result is Success, isTrue);
          final node = result.value as UrlNode;
          expect(node.url, equals('https://example.com/path[1]'));
        });

        test('ネストした括弧を含むURL', () {
          final result = parser.parse(
            'https://example.com/wiki/Test_(foo_(bar))',
          );
          expect(result is Success, isTrue);
          final node = result.value as UrlNode;
          expect(node.url, equals('https://example.com/wiki/Test_(foo_(bar))'));
        });

        test('閉じ括弧がない場合は括弧で終了', () {
          final result = parser.parse('https://example.com/(test');
          expect(result is Success, isTrue);
          final node = result.value as UrlNode;
          expect(node.url, equals('https://example.com/'));
        });
      });

      group('末尾の無効文字除去', () {
        test('末尾のピリオドを除去', () {
          final result = parser.parse('https://example.com.');
          expect(result is Success, isTrue);
          final node = result.value as UrlNode;
          expect(node.url, equals('https://example.com'));
        });

        test('末尾のカンマを除去', () {
          final result = parser.parse('https://example.com,');
          expect(result is Success, isTrue);
          final node = result.value as UrlNode;
          expect(node.url, equals('https://example.com'));
        });

        test('末尾の複数ピリオド・カンマを除去', () {
          final result = parser.parse('https://example.com.,.');
          expect(result is Success, isTrue);
          final node = result.value as UrlNode;
          expect(node.url, equals('https://example.com'));
        });

        test('パス内のピリオドは保持', () {
          final result = parser.parse('https://example.com/file.html');
          expect(result is Success, isTrue);
          final node = result.value as UrlNode;
          expect(node.url, equals('https://example.com/file.html'));
        });
      });

      group('無効なケース', () {
        test('スキーマがない場合は失敗', () {
          final result = parser.parse('example.com');
          expect(result is Failure, isTrue);
        });

        test('ftp:// は失敗', () {
          final result = parser.parse('ftp://example.com');
          expect(result is Failure, isTrue);
        });

        test('スキーマのみは失敗', () {
          final result = parser.parse('https://');
          expect(result is Failure, isTrue);
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

    group('フォールバック付きパーサー（buildWithFallback）', () {
      final parser = UrlParser().buildWithFallback();

      test('有効なURLはUrlNodeとして解析', () {
        final result = parser.parse('https://example.com');
        expect(result is Success, isTrue);
        expect(result.value, isA<UrlNode>());
      });

      test('スキーマのみの場合はTextNodeとしてフォールバック', () {
        final result = parser.parse('https://');
        expect(result is Success, isTrue);
        expect(result.value, isA<TextNode>());
        expect((result.value as TextNode).text, equals('https://'));
      });

      test('http://のみの場合もTextNodeとしてフォールバック', () {
        final result = parser.parse('http://');
        expect(result is Success, isTrue);
        expect(result.value, isA<TextNode>());
        expect((result.value as TextNode).text, equals('http://'));
      });
    });
  });

  group('mfm-js互換テスト', () {
    final parser = MfmParser().build();

    group('edge cases', () {
      test('disallow period only', () {
        // mfm-js: https://. はURLとして認識されず、テキストとして扱われる
        final result = parser.parse('https://.');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, equals('https://.'));
      });
    });

    group('parent brackets handling', () {
      test('ignore parent brackets', () {
        // mfm-js: 親括弧内のURLは括弧を含まない
        final result = parser.parse('(https://example.com/foo)');
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

      test('ignore parent brackets (2)', () {
        // mfm-js: テキスト後の親括弧内URLも同様
        final result = parser.parse('(foo https://example.com/foo)');
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

      test('ignore parent brackets with internal brackets', () {
        // mfm-js: 内部括弧を含むURLは内部括弧を保持し、親括弧は除外
        final result = parser.parse('(https://example.com/foo(bar))');
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

      test('ignore parent []', () {
        // mfm-js: 角括弧内のURLも同様に処理
        final result = parser.parse('foo [https://example.com/foo] bar');
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
        'ignore non-ascii characters contained url without angle brackets',
        () {
          // mfm-js: 非ASCII文字を含むURLはブラケットなしではテキストとして扱う
          final result = parser.parse('https://大石泉すき.example.com');
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

      test('match non-ascii characters contained url with angle brackets', () {
        // mfm-js: ブラケット付きなら非ASCII文字を含むURLも認識
        final result = parser.parse('<https://大石泉すき.example.com>');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        expect(nodes[0], isA<UrlNode>());
        final urlNode = nodes[0] as UrlNode;
        expect(urlNode.url, equals('https://大石泉すき.example.com'));
        expect(urlNode.brackets, isTrue);
      });

      test('prevent xss', () {
        // mfm-js: javascript: スキームはURLとして認識しない（XSS防止）
        final result = parser.parse('javascript:foo');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, equals('javascript:foo'));
      });
    });
  });
}
