import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('FnParser 基本構文テスト', () {
    final parser = MfmParser().build();

    test('tadaエフェクトを解析できる', () {
      final result = parser.parse(r'$[tada 🎉]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'tada',
          args: {},
          children: [
            UnicodeEmojiNode('🎉'),
          ],
        ),
      ]);
    });

    test('spinエフェクトを解析できる', () {
      final result = parser.parse(r'$[spin text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'spin',
          args: {},
          children: [
            TextNode('text'),
          ],
        ),
      ]);
    });

    test('未知の関数名でも解析できる', () {
      final result = parser.parse(r'$[unknown_func content]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'unknown_func',
          args: {},
          children: [
            TextNode('content'),
          ],
        ),
      ]);
    });
  });

  group('FnParser 引数バリエーションテスト', () {
    final parser = MfmParser().build();

    test('単一のkey=value引数を解析できる', () {
      final result = parser.parse(r'$[spin.speed=2s text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'spin',
          args: {
            'speed': '2s',
          },
          children: [
            TextNode('text'),
          ],
        ),
      ]);
    });

    test('複数のboolean引数を解析できる', () {
      final result = parser.parse(r'$[flip.h,v content]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'flip',
          args: {
            'h': true,
            'v': true,
          },
          children: [
            TextNode('content'),
          ],
        ),
      ]);
    });

    test('混合引数（boolean + key=value）を解析できる', () {
      final result = parser.parse(r'$[spin.left,speed=1.5s text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'spin',
          args: {
            'left': true,
            'speed': '1.5s',
          },
          children: [
            TextNode('text'),
          ],
        ),
      ]);
    });

    test('border関数の複数引数を解析できる', () {
      final result = parser.parse(
        r'$[border.color=ff0000,width=2,radius=5 text]',
      );
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'border',
          args: {
            'color': 'ff0000',
            'width': '2',
            'radius': '5',
          },
          children: [
            TextNode('text'),
          ],
        ),
      ]);
    });
  });

  group('FnParser ネスト構文テスト', () {
    final parser = MfmParser().build();

    test('fn内にボールドをネストできる', () {
      final result = parser.parse(r'$[shake **bold**]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'shake',
          args: {},
          children: [
            BoldNode([TextNode('bold')]),
          ],
        ),
      ]);
    });

    test('fn内にイタリックをネストできる', () {
      final result = parser.parse(r'$[tada <i>italic</i>]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'tada',
          args: {},
          children: [
            ItalicNode([TextNode('italic')]),
          ],
        ),
      ]);
    });

    test('fn内に絵文字コードをネストできる', () {
      final result = parser.parse(r'$[shake :emoji:]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'shake',
          args: {},
          children: [
            EmojiCodeNode('emoji'),
          ],
        ),
      ]);
    });

    test('fn内にUnicode絵文字をネストできる', () {
      final result = parser.parse(r'$[spin 🍮]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'spin',
          args: {},
          children: [
            UnicodeEmojiNode('🍮'),
          ],
        ),
      ]);
    });

    test('fn内に複数のノードをネストできる', () {
      final result = parser.parse(r'$[shake text **bold** more]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'shake',
          args: {},
          children: [
            TextNode('text '),
            BoldNode([TextNode('bold')]),
            TextNode(' more'),
          ],
        ),
      ]);
    });

    test('ボールド内にfnをネストできる', () {
      final result = parser.parse(r'**$[shake text]**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const BoldNode([
          FnNode(
            name: 'shake',
            args: {},
            children: [
              TextNode('text'),
            ],
          ),
        ]),
      ]);
    });
  });

  group('FnParser フォールバックテスト', () {
    final parser = MfmParser().build();

    test('閉じ括弧がない場合はテキストとして扱う', () {
      final result = parser.parse(r'$[shake text');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [const TextNode(r'$[shake text')]);
    });

    test('スペースがない場合はテキストとして扱う', () {
      final result = parser.parse(r'$[shaketext]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [const TextNode(r'$[shaketext]')]);
    });

    test(r'単独の$[はテキストとして扱う', () {
      final result = parser.parse(r'$[');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [const TextNode(r'$[')]);
    });
  });

  group('FnParser エッジケーステスト', () {
    final parser = MfmParser().build();

    test('テキストとfnの組み合わせ', () {
      final result = parser.parse(r'before $[shake text] after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('before '),
        const FnNode(
          name: 'shake',
          args: {},
          children: [
            TextNode('text'),
          ],
        ),
        const TextNode(' after'),
      ]);
    });

    test('複数のfnを連続で解析できる', () {
      final result = parser.parse(r'$[shake a] $[spin b]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'shake',
          args: {},
          children: [
            TextNode('a'),
          ],
        ),
        const TextNode(' '),
        const FnNode(
          name: 'spin',
          args: {},
          children: [
            TextNode('b'),
          ],
        ),
      ]);
    });

    test('サイズ関数（x2, x3, x4）を解析できる', () {
      final result = parser.parse(r'$[x2 big text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'x2',
          args: {},
          children: [
            TextNode('big text'),
          ],
        ),
      ]);
    });

    test('色指定関数を解析できる', () {
      final result = parser.parse(r'$[fg.color=ff0000 red text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'fg',
          args: {
            'color': 'ff0000',
          },
          children: [
            TextNode('red text'),
          ],
        ),
      ]);
    });

    test('font関数を解析できる', () {
      final result = parser.parse(r'$[font.serif text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'font',
          args: {
            'serif': true,
          },
          children: [
            TextNode('text'),
          ],
        ),
      ]);
    });

    test('rotate関数のdeg引数を解析できる', () {
      final result = parser.parse(r'$[rotate.deg=45 text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'rotate',
          args: {
            'deg': '45',
          },
          children: [
            TextNode('text'),
          ],
        ),
      ]);
    });

    test('scale関数の座標引数を解析できる', () {
      final result = parser.parse(r'$[scale.x=2,y=0.5 text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'scale',
          args: {
            'x': '2',
            'y': '0.5',
          },
          children: [
            TextNode('text'),
          ],
        ),
      ]);
    });

    test('fn内で改行を含む内容を解析できる', () {
      final result = parser.parse('\$[shake line1\nline2]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'shake',
          args: {},
          children: [
            TextNode('line1\nline2'),
          ],
        ),
      ]);
    });

    test('リンク内でfnを使用できる', () {
      final result = parser.parse(r'[$[shake click me]](https://example.com)');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const LinkNode(
          silent: false,
          url: 'https://example.com',
          children: [
            FnNode(
              name: 'shake',
              args: {},
              children: [
                TextNode('click me'),
              ],
            ),
          ],
        ),
      ]);
    });
  });

  group('FnParser 廃止予定構文テスト', () {
    final parser = MfmParser().build();

    // ***big*** は mfm-js では $[tada ...] として解釈される
    // 本実装では別途対応が必要（現時点ではテストのみ記載）
    test('fn構文で代替可能な機能のテスト', () {
      // $[tada text] で ***text*** の代替
      final result = parser.parse(r'$[tada big text!]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const FnNode(
          name: 'tada',
          args: {},
          children: [
            TextNode('big text!'),
          ],
        ),
      ]);
    });
  });
}
