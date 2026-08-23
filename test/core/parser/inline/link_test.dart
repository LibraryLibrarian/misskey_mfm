import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/core/nest.dart';
import 'package:misskey_mfm_parser/src/parser/inline/link.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
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
        expect(nodes, [const TextNode('[')]);
      });

      test('?[のみの場合はTextNode', () {
        final result = fullParser.parse('?[');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('?[')]);
      });

      test('不完全なリンクはTextNode', () {
        final result = fullParser.parse('[Link');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.any((n) => n is LinkNode), isFalse);
      });
    });

    group('ラベルのネスト深度', () {
      const input = '[**Bold Link**](https://example.com)';

      for (final limit in [0, 1]) {
        test('nestLimit=$limit ではラベル内構文を文字として扱う', () {
          final result = MfmParser().build(nestLimit: limit).parse(input);
          expect(result, isA<Success<List<MfmNode>>>());
          expect(result.position, input.length);
          expect(result.value, [
            const LinkNode(
              silent: false,
              url: 'https://example.com',
              children: [TextNode('**Bold Link**')],
            ),
          ]);
        });
      }

      test('nestLimit=2 ではラベル直下の構文を解析する', () {
        final result = MfmParser().build(nestLimit: 2).parse(input);
        expect(result, isA<Success<List<MfmNode>>>());
        expect(result.position, input.length);
        expect(result.value, [
          const LinkNode(
            silent: false,
            url: 'https://example.com',
            children: [
              BoldNode([TextNode('Bold Link')]),
            ],
          ),
        ]);
      });

      test('深いラベル構文は深度上限で文字列へフォールバックする', () {
        const deepInput = '[**<small>deep</small>**](https://example.com)';
        final result = MfmParser().build(nestLimit: 2).parse(deepInput);
        expect(result, isA<Success<List<MfmNode>>>());
        expect(result.position, deepInput.length);
        expect(result.value, [
          const LinkNode(
            silent: false,
            url: 'https://example.com',
            children: [
              BoldNode([TextNode('<small>deep</small>')]),
            ],
          ),
        ]);
      });

      test('通常ラベルとlink-likeな文字列の既存挙動を維持する', () {
        const normalInput =
            '[label https://example.com @user](https://outer.example)';
        final result = fullParser.parse(normalInput);
        expect(result, isA<Success<List<MfmNode>>>());
        expect(result.position, normalInput.length);
        expect(result.value, [
          const LinkNode(
            silent: false,
            url: 'https://outer.example',
            children: [TextNode('label https://example.com @user')],
          ),
        ]);
      });

      test('各ラベル要素で深度を1回だけ増減し状態を再利用できる', () {
        final state = NestState(limit: 20);
        final observedDepths = <int>[];
        final labelParser = any().map<MfmNode>((dynamic value) {
          observedDepths.add(state.depth);
          return TextNode(value as String);
        });
        final parser = LinkParser().buildWithInner(
          labelParser,
          state: state,
        );

        final first = parser.parse('[ab](https://example.com)');
        expect(first, isA<Success<MfmNode>>());
        expect(first.position, '[ab](https://example.com)'.length);
        expect(observedDepths, [1, 1]);
        expect(state.depth, 0);

        observedDepths.clear();
        final lookahead = parser.and().parse('[c](https://example.com)');
        expect(lookahead, isA<Success<MfmNode>>());
        expect(lookahead.position, 0);
        expect(observedDepths, [1]);
        expect(state.depth, 0);

        observedDepths.clear();
        final failure = parser.parse('[d](invalid)');
        expect(failure, isA<Failure>());
        expect(observedDepths, [1]);
        expect(state.depth, 0);

        observedDepths.clear();
        final reused = parser.parse('[e](https://example.com)');
        expect(reused, isA<Success<MfmNode>>());
        expect(observedDepths, [1]);
        expect(state.depth, 0);
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
        expect(nodes, [
          const TextNode('Check out '),
          const UrlNode(url: 'https://example.com'),
          const TextNode(' for more'),
        ]);
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
        expect(nodes, [
          const LinkNode(
            silent: false,
            url: 'https://misskey.io/',
            children: [TextNode('Misskey')],
          ),
        ]);
      });

      test('サイレントリンク', () {
        final result = fullParser.parse('?[Misskey](https://misskey.io/)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes, [
          const LinkNode(
            silent: true,
            url: 'https://misskey.io/',
            children: [TextNode('Misskey')],
          ),
        ]);
      });

      test('テキスト内のリンク', () {
        final result = fullParser.parse(
          'Visit [Misskey](https://misskey.io/) today!',
        );
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes, [
          const TextNode('Visit '),
          const LinkNode(
            silent: false,
            url: 'https://misskey.io/',
            children: [TextNode('Misskey')],
          ),
          const TextNode(' today!'),
        ]);
      });

      test('ラベル内のインライン構文', () {
        final result = fullParser.parse('[**Bold Link**](https://example.com)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes, [
          const LinkNode(
            silent: false,
            url: 'https://example.com',
            children: [
              BoldNode([TextNode('Bold Link')]),
            ],
          ),
        ]);
      });

      test('ラベル内の絵文字コード', () {
        final result = fullParser.parse('[:smile: Link](https://example.com)');
        expect(result is Success, isTrue);
        final nodes = result.value;
        expect(nodes, [
          const LinkNode(
            silent: false,
            url: 'https://example.com',
            children: [
              EmojiCodeNode('smile'),
              TextNode(' Link'),
            ],
          ),
        ]);
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
