import 'dart:convert';

import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:test/test.dart';

import '../support/ast_json.dart';

void main() {
  group('AST golden serializer', () {
    test('sealed MfmNodeの全variantとnullable/default値を保持する', () {
      const nodes = <MfmNode>[
        TextNode('line1\n行2'),
        InlineCodeNode('code'),
        EmojiCodeNode('wave'),
        UnicodeEmojiNode('🍋‍🟩'),
        HashtagNode('タグ'),
        MathBlockNode('x\r\n+y'),
        MathInlineNode('x+1'),
        BoldNode([TextNode('bold')]),
        ItalicNode([TextNode('italic')]),
        StrikeNode([TextNode('strike')]),
        SmallNode([TextNode('small')]),
        QuoteNode([TextNode('quote')]),
        CenterNode([TextNode('center')]),
        PlainNode([TextNode('**plain**')]),
        UrlNode(url: 'https://example.com'),
        UrlNode(url: 'https://example.com/a', brackets: true),
        LinkNode(
          silent: false,
          url: 'https://example.com',
          children: [TextNode('label')],
        ),
        LinkNode(
          silent: true,
          url: 'https://example.com/silent',
          children: [TextNode('silent')],
        ),
        // The explicit null is intentional: golden JSON must retain it.
        // ignore: avoid_redundant_argument_values
        MentionNode(username: 'local', host: null, acct: '@local'),
        MentionNode(
          username: 'remote',
          host: 'example.com',
          acct: '@remote@example.com',
        ),
        FnNode(
          name: 'spin',
          args: {
            'z': true,
            'a': '1',
            'nested': {'b': 2, 'a': 1},
          },
          children: [TextNode('fn')],
        ),
        // The explicit null is intentional: golden JSON must retain it.
        // ignore: avoid_redundant_argument_values
        CodeBlockNode(code: 'code\nline', language: null),
        CodeBlockNode(code: 'void main() {}', language: 'dart'),
        SearchNode(query: 'MFM 書き方', content: 'MFM 書き方 Search'),
      ];

      final serialized = serializeMfmAst(nodes);
      final types = serialized
          .map((node) => node['type'])
          .whereType<String>()
          .toSet();

      expect(types, {
        'text',
        'inlineCode',
        'emojiCode',
        'unicodeEmoji',
        'hashtag',
        'mathBlock',
        'mathInline',
        'bold',
        'italic',
        'strike',
        'small',
        'quote',
        'center',
        'plain',
        'url',
        'link',
        'mention',
        'fn',
        'codeBlock',
        'search',
      });

      expect(serialized[14]['props'], {
        'brackets': false,
        'url': 'https://example.com',
      });
      expect(serialized[18]['props'], {
        'acct': '@local',
        'host': null,
        'username': 'local',
      });
      expect(serialized[21]['props'], {
        'code': 'code\nline',
        'language': null,
      });
      for (final node in serialized) {
        expect(node.keys, ['type', 'props', 'children']);
      }
    });

    test('Fn argsを再帰的なキー順で決定的にserializeする', () {
      const node = FnNode(
        name: 'test',
        args: {
          'z': true,
          'a': 'first',
          'nested': {'z': 2, 'a': 1},
        },
        children: [TextNode('内容')],
      );

      final first = jsonEncode(serializeMfmNode(node));
      final second = jsonEncode(serializeMfmNode(node));

      expect(first, second);
      expect(
        first,
        '{"type":"fn","props":{"args":{"a":"first",'
        '"nested":{"a":1,"z":2},"z":true},"name":"test"},'
        '"children":[{"type":"text","props":{"text":"内容"},'
        '"children":[]}]}',
      );
    });

    test('JSON-safeなprimitiveとnested list/mapを決定的に保持する', () {
      const node = FnNode(
        name: 'json',
        args: {
          'string': 'value',
          'bool': false,
          'int': 42,
          'double': 1.5,
          'null': null,
          'list': [
            1,
            2.5,
            true,
            'text',
            null,
            {'z': 2, 'a': 1},
          ],
        },
        children: [],
      );

      final first = jsonEncode(serializeMfmNode(node));
      final second = jsonEncode(serializeMfmNode(node));

      expect(first, second);
      expect(
        jsonDecode(first),
        {
          'type': 'fn',
          'props': {
            'args': {
              'bool': false,
              'double': 1.5,
              'int': 42,
              'list': [
                1,
                2.5,
                true,
                'text',
                null,
                {'a': 1, 'z': 2},
              ],
              'null': null,
              'string': 'value',
            },
            'name': 'json',
          },
          'children': <Object?>[],
        },
      );
    });

    for (final invalidNumber in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      test('JSON非互換の数値 $invalidNumber を拒否する', () {
        final node = FnNode(
          name: 'invalid',
          args: {'value': invalidNumber},
          children: const [],
        );

        expect(
          () => serializeMfmNode(node),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              contains('finite JSON values'),
            ),
          ),
        );
      });
    }
  });
}
