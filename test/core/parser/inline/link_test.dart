import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser/inline/link.dart';
import 'package:misskey_mfm/core/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('LinkParser', () {
    // シンプルなラベル用パーサー（テキストのみ）
    final simpleLabelParser = any().map<MfmNode>(
      (dynamic c) => TextNode(c as String),
    );

    group('通常リンク（buildWithInner）', () {
      final parser = LinkParser().buildWithInner(simpleLabelParser);

      test('基本的なリンク', () {
        final result = parser.parse('[Example](https://example.com)');
        expect(result is Success, isTrue);
        final node = result.value as LinkNode;
        expect(node.silent, isFalse);
        expect(node.url, equals('https://example.com'));
        expect(node.children.length, equals(1));
        expect((node.children[0] as TextNode).text, equals('Example'));
      });

      test('パス付きURL', () {
        final result = parser.parse('[Link](https://example.com/path/to/page)');
        expect(result is Success, isTrue);
        final node = result.value as LinkNode;
        expect(node.url, equals('https://example.com/path/to/page'));
      });

      test('HTTP URL', () {
        final result = parser.parse('[Link](http://example.com)');
        expect(result is Success, isTrue);
        final node = result.value as LinkNode;
        expect(node.url, equals('http://example.com'));
      });

      test('日本語ラベル', () {
        final result = parser.parse('[リンクテキスト](https://example.com)');
        expect(result is Success, isTrue);
        final node = result.value as LinkNode;
        expect(node.children.isNotEmpty, isTrue);
      });

      test('複数単語のラベル', () {
        final result = parser.parse(
          '[Click here for more](https://example.com)',
        );
        expect(result is Success, isTrue);
        final node = result.value as LinkNode;
        expect(node.children.isNotEmpty, isTrue);
      });

      test('ブラケット付きURL', () {
        final result = parser.parse('[Link](<https://example.com/@user>)');
        expect(result is Success, isTrue);
        final node = result.value as LinkNode;
        expect(node.url, equals('https://example.com/@user'));
      });

      group('無効なケース', () {
        test('空のラベルは失敗', () {
          final result = parser.parse('[](https://example.com)');
          expect(result is Failure, isTrue);
        });

        test('閉じ括弧がない場合は失敗', () {
          final result = parser.parse('[Link](https://example.com');
          expect(result is Failure, isTrue);
        });

        test('URLがない場合は失敗', () {
          final result = parser.parse('[Link]()');
          expect(result is Failure, isTrue);
        });

        test('無効なURLは失敗', () {
          final result = parser.parse('[Link](not-a-url)');
          expect(result is Failure, isTrue);
        });

        test('ラベル内の改行は失敗', () {
          final result = parser.parse('[Line1\nLine2](https://example.com)');
          expect(result is Failure, isTrue);
        });
      });
    });

    group('サイレントリンク', () {
      final parser = LinkParser().buildWithInner(simpleLabelParser);

      test('基本的なサイレントリンク', () {
        final result = parser.parse('?[Example](https://example.com)');
        expect(result is Success, isTrue);
        final node = result.value as LinkNode;
        expect(node.silent, isTrue);
        expect(node.url, equals('https://example.com'));
      });

      test('パス付きサイレントリンク', () {
        final result = parser.parse('?[Link](https://example.com/path)');
        expect(result is Success, isTrue);
        final node = result.value as LinkNode;
        expect(node.silent, isTrue);
        expect(node.url, equals('https://example.com/path'));
      });
    });

    group('フォールバック付きパーサー（buildWithFallback）', () {
      final parser = LinkParser().buildWithFallback(simpleLabelParser);

      test('有効なリンクはLinkNodeとして解析', () {
        final result = parser.parse('[Link](https://example.com)');
        expect(result is Success, isTrue);
        expect(result.value, isA<LinkNode>());
      });

      test('[のみの場合はTextNodeとしてフォールバック', () {
        final result = parser.parse('[');
        expect(result is Success, isTrue);
        expect(result.value, isA<TextNode>());
        expect((result.value as TextNode).text, equals('['));
      });

      test('?[のみの場合はTextNodeとしてフォールバック', () {
        final result = parser.parse('?[');
        expect(result is Success, isTrue);
        expect(result.value, isA<TextNode>());
        expect((result.value as TextNode).text, equals('?['));
      });

      test('不完全なリンクはTextNodeとしてフォールバック', () {
        final result = parser.parse('[Link');
        expect(result is Success, isTrue);
        expect(result.value, isA<TextNode>());
      });
    });
  });

  group('MfmParser統合テスト', () {
    final parser = MfmParser().build();

    group('URL自動リンク', () {
      test('テキスト内のURL', () {
        final result = parser.parse('Check out https://example.com for more');
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
        final result = parser.parse('https://a.com and https://b.com');
        expect(result is Success, isTrue);
        final nodes = result.value;
        final urlNodes = nodes.whereType<UrlNode>().toList();
        expect(urlNodes.length, equals(2));
        expect(urlNodes[0].url, equals('https://a.com'));
        expect(urlNodes[1].url, equals('https://b.com'));
      });

      test('ブラケット付きURL', () {
        final result = parser.parse('See <https://example.com/@user> here');
        expect(result is Success, isTrue);
        final nodes = result.value;
        final urlNode = nodes.whereType<UrlNode>().first;
        expect(urlNode.url, equals('https://example.com/@user'));
        expect(urlNode.brackets, isTrue);
      });

      test('末尾のピリオドを除去', () {
        final result = parser.parse('Visit https://example.com.');
        expect(result is Success, isTrue);
        final nodes = result.value;
        final urlNode = nodes.whereType<UrlNode>().first;
        expect(urlNode.url, equals('https://example.com'));
      });

      test('括弧を含むURL（Wikipedia形式）', () {
        final result = parser.parse(
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
        final result = parser.parse('[Misskey](https://misskey.io/)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        final linkNode = nodes[0] as LinkNode;
        expect(linkNode.silent, isFalse);
        expect(linkNode.url, equals('https://misskey.io/'));
      });

      test('サイレントリンク', () {
        final result = parser.parse('?[Misskey](https://misskey.io/)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        final linkNode = nodes[0] as LinkNode;
        expect(linkNode.silent, isTrue);
        expect(linkNode.url, equals('https://misskey.io/'));
      });

      test('テキスト内のリンク', () {
        final result = parser.parse(
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
        final result = parser.parse('[**Bold Link**](https://example.com)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        final linkNode = nodes[0] as LinkNode;
        // ラベル内にBoldNodeが含まれる
        expect(linkNode.children.any((n) => n is BoldNode), isTrue);
      });

      test('ラベル内の絵文字コード', () {
        final result = parser.parse('[:smile: Link](https://example.com)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        final linkNode = nodes[0] as LinkNode;
        expect(linkNode.children.any((n) => n is EmojiCodeNode), isTrue);
      });
    });

    group('URL/リンクと他の構文の組み合わせ', () {
      test('URLとメンション', () {
        final result = parser.parse('@user https://example.com');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.whereType<MentionNode>().length, equals(1));
        expect(nodes.whereType<UrlNode>().length, equals(1));
      });

      test('URLとハッシュタグ', () {
        final result = parser.parse('https://example.com #test');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.whereType<UrlNode>().length, equals(1));
        expect(nodes.whereType<HashtagNode>().length, equals(1));
      });

      test('リンクと絵文字', () {
        final result = parser.parse(':smile: [Link](https://example.com)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.whereType<EmojiCodeNode>().length, equals(1));
        expect(nodes.whereType<LinkNode>().length, equals(1));
      });

      test('引用内のURL', () {
        final result = parser.parse('> https://example.com');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        final quoteNode = nodes[0] as QuoteNode;
        expect(quoteNode.children.any((n) => n is UrlNode), isTrue);
      });

      test('太字内のURL', () {
        final result = parser.parse('**https://example.com**');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes.length, equals(1));
        final boldNode = nodes[0] as BoldNode;
        expect(boldNode.children.any((n) => n is UrlNode), isTrue);
      });
    });
  });
}
