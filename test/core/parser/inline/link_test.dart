import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  // フルパーサーを使用（mfm-js互換のテスト）
  final fullParser = MfmParser().build();

  /// ヘルパー: フルパーサーの結果から最初のLinkNodeを取得
  LinkNode? getFirstLink(Result<List<MfmNode>> result) {
    if (result is! Success) return null;
    final nodes = result.value;
    for (final node in nodes) {
      if (node is LinkNode) return node;
    }
    return null;
  }

  group('LinkParser', () {
    group('通常リンク（フルパーサー経由）', () {
      test('パス付きURL', () {
        final result = fullParser.parse(
          '[Link](https://example.com/path/to/page)',
        );
        expect(result is Success, isTrue);
        final node = getFirstLink(result);
        expect(node, isNotNull);
        expect(node!.url, equals('https://example.com/path/to/page'));
      });

      test('HTTP URL', () {
        final result = fullParser.parse('[Link](http://example.com)');
        expect(result is Success, isTrue);
        final node = getFirstLink(result);
        expect(node, isNotNull);
        expect(node!.url, equals('http://example.com'));
      });

      test('日本語ラベル', () {
        final result = fullParser.parse('[リンクテキスト](https://example.com)');
        expect(result is Success, isTrue);
        final node = getFirstLink(result);
        expect(node, isNotNull);
        expect(node!.children.isNotEmpty, isTrue);
      });

      test('複数単語のラベル', () {
        final result = fullParser.parse(
          '[Click here for more](https://example.com)',
        );
        expect(result is Success, isTrue);
        final node = getFirstLink(result);
        expect(node, isNotNull);
        expect(node!.children.isNotEmpty, isTrue);
      });

      test('ブラケット付きURL', () {
        final result = fullParser.parse('[Link](<https://example.com/@user>)');
        expect(result is Success, isTrue);
        final node = getFirstLink(result);
        expect(node, isNotNull);
        expect(node!.url, equals('https://example.com/@user'));
      });

      group('無効なケース', () {
        test('空のラベルはテキスト', () {
          final result = fullParser.parse('[](https://example.com)');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          // 空のラベルはリンクとして認識されない
          expect(nodes.any((n) => n is LinkNode), isFalse);
        });

        test('閉じ括弧がない場合はテキスト', () {
          final result = fullParser.parse('[Link](https://example.com');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes.any((n) => n is LinkNode), isFalse);
        });

        test('URLがない場合はテキスト', () {
          final result = fullParser.parse('[Link]()');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes.any((n) => n is LinkNode), isFalse);
        });

        test('無効なURLはテキスト', () {
          final result = fullParser.parse('[Link](not-a-url)');
          expect(result is Success, isTrue);
          final nodes = (result as Success).value as List<MfmNode>;
          expect(nodes.any((n) => n is LinkNode), isFalse);
        });
      });
    });

    group('サイレントリンク', () {
      test('パス付きサイレントリンク', () {
        final result = fullParser.parse('?[Link](https://example.com/path)');
        expect(result is Success, isTrue);
        final node = getFirstLink(result);
        expect(node, isNotNull);
        expect(node!.silent, isTrue);
        expect(node.url, equals('https://example.com/path'));
      });
    });

    group('フォールバック（フルパーサー経由）', () {
      test('有効なリンクはLinkNodeとして解析', () {
        final result = fullParser.parse('[Link](https://example.com)');
        expect(result is Success, isTrue);
        final node = getFirstLink(result);
        expect(node, isNotNull);
      });

      test('[のみの場合はTextNode', () {
        final result = fullParser.parse('[');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, equals('['));
      });

      test('?[のみの場合はTextNode', () {
        final result = fullParser.parse('?[');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, equals('?['));
      });

      test('不完全なリンクはTextNode', () {
        final result = fullParser.parse('[Link');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.any((n) => n is LinkNode), isFalse);
      });
    });
  });

  group('MfmParser統合テスト', () {
    group('URL自動リンク', () {
      test('テキスト内のURL', () {
        final result = fullParser.parse(
          'Check out https://example.com for more',
        );
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(3));
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, equals('Check out '));
        expect(nodes[1], isA<UrlNode>());
        expect((nodes[1] as UrlNode).url, equals('https://example.com'));
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, equals(' for more'));
      });

      test('複数のURL', () {
        final result = fullParser.parse('https://a.com and https://b.com');
        expect(result is Success, isTrue);
        final nodes = result.value;
        final urlNodes = nodes.whereType<UrlNode>().toList();
        expect(urlNodes.length, equals(2));
        expect(urlNodes[0].url, equals('https://a.com'));
        expect(urlNodes[1].url, equals('https://b.com'));
      });

      test('ブラケット付きURL', () {
        final result = fullParser.parse('See <https://example.com/@user> here');
        expect(result is Success, isTrue);
        final nodes = result.value;
        final urlNode = nodes.whereType<UrlNode>().first;
        expect(urlNode.url, equals('https://example.com/@user'));
        expect(urlNode.brackets, isTrue);
      });

      test('末尾のピリオドを除去', () {
        final result = fullParser.parse('Visit https://example.com.');
        expect(result is Success, isTrue);
        final nodes = result.value;
        final urlNode = nodes.whereType<UrlNode>().first;
        expect(urlNode.url, equals('https://example.com'));
      });

      test('括弧を含むURL（Wikipedia形式）', () {
        final result = fullParser.parse(
          'https://en.wikipedia.org/wiki/Dart_(programming_language)',
        );
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        final urlNode = nodes[0] as UrlNode;
        expect(
          urlNode.url,
          equals('https://en.wikipedia.org/wiki/Dart_(programming_language)'),
        );
      });
    });

    group('Markdownリンク', () {
      test('基本的なリンク', () {
        final result = fullParser.parse('[Misskey](https://misskey.io/)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        final linkNode = nodes[0] as LinkNode;
        expect(linkNode.silent, isFalse);
        expect(linkNode.url, equals('https://misskey.io/'));
      });

      test('サイレントリンク', () {
        final result = fullParser.parse('?[Misskey](https://misskey.io/)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        final linkNode = nodes[0] as LinkNode;
        expect(linkNode.silent, isTrue);
        expect(linkNode.url, equals('https://misskey.io/'));
      });

      test('テキスト内のリンク', () {
        final result = fullParser.parse(
          'Visit [Misskey](https://misskey.io/) today!',
        );
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(3));
        expect(nodes[0], isA<TextNode>());
        expect(nodes[1], isA<LinkNode>());
        expect(nodes[2], isA<TextNode>());
      });

      test('ラベル内のインライン構文', () {
        final result = fullParser.parse('[**Bold Link**](https://example.com)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        final linkNode = nodes[0] as LinkNode;
        // ラベル内にBoldNodeが含まれる
        expect(linkNode.children.any((n) => n is BoldNode), isTrue);
      });

      test('ラベル内の絵文字コード', () {
        final result = fullParser.parse('[:smile: Link](https://example.com)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        final linkNode = nodes[0] as LinkNode;
        expect(linkNode.children.any((n) => n is EmojiCodeNode), isTrue);
      });
    });

    group('URL/リンクと他の構文の組み合わせ', () {
      test('URLとメンション', () {
        final result = fullParser.parse('@user https://example.com');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.whereType<MentionNode>().length, equals(1));
        expect(nodes.whereType<UrlNode>().length, equals(1));
      });

      test('URLとハッシュタグ', () {
        final result = fullParser.parse('https://example.com #test');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.whereType<UrlNode>().length, equals(1));
        expect(nodes.whereType<HashtagNode>().length, equals(1));
      });

      test('リンクと絵文字', () {
        final result = fullParser.parse(':smile: [Link](https://example.com)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.whereType<EmojiCodeNode>().length, equals(1));
        expect(nodes.whereType<LinkNode>().length, equals(1));
      });

      test('引用内のURL', () {
        final result = fullParser.parse('> https://example.com');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        final quoteNode = nodes[0] as QuoteNode;
        expect(quoteNode.children.any((n) => n is UrlNode), isTrue);
      });

      test('太字内のURL', () {
        final result = fullParser.parse('**https://example.com**');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        final boldNode = nodes[0] as BoldNode;
        expect(boldNode.children.any((n) => n is UrlNode), isTrue);
      });
    });
  });
}
