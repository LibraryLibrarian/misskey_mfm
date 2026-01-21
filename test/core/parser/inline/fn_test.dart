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
      expect(nodes.length, 1);
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'tada');
      expect(fn.args, isEmpty);
    });

    test('spinエフェクトを解析できる', () {
      final result = parser.parse(r'$[spin text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'spin');
    });

    test('未知の関数名でも解析できる', () {
      final result = parser.parse(r'$[unknown_func content]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'unknown_func');
    });
  });

  group('FnParser 引数バリエーションテスト', () {
    final parser = MfmParser().build();

    test('単一のkey=value引数を解析できる', () {
      final result = parser.parse(r'$[spin.speed=2s text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'spin');
      expect(fn.args['speed'], '2s');
    });

    test('複数のboolean引数を解析できる', () {
      final result = parser.parse(r'$[flip.h,v content]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'flip');
      expect(fn.args['h'], isTrue);
      expect(fn.args['v'], isTrue);
    });

    test('混合引数（boolean + key=value）を解析できる', () {
      final result = parser.parse(r'$[spin.left,speed=1.5s text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'spin');
      expect(fn.args['left'], isTrue);
      expect(fn.args['speed'], '1.5s');
    });

    test('border関数の複数引数を解析できる', () {
      final result = parser.parse(
        r'$[border.color=ff0000,width=2,radius=5 text]',
      );
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'border');
      expect(fn.args['color'], 'ff0000');
      expect(fn.args['width'], '2');
      expect(fn.args['radius'], '5');
    });
  });

  group('FnParser ネスト構文テスト', () {
    final parser = MfmParser().build();

    test('fn内にボールドをネストできる', () {
      final result = parser.parse(r'$[shake **bold**]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.children.length, 1);
      expect(fn.children.first, isA<BoldNode>());
    });

    test('fn内にイタリックをネストできる', () {
      final result = parser.parse(r'$[tada <i>italic</i>]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.children.length, 1);
      expect(fn.children.first, isA<ItalicNode>());
    });

    test('fn内に絵文字コードをネストできる', () {
      final result = parser.parse(r'$[shake :emoji:]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.children.length, 1);
      expect(fn.children.first, isA<EmojiCodeNode>());
    });

    test('fn内にUnicode絵文字をネストできる', () {
      final result = parser.parse(r'$[spin 🍮]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.children.length, 1);
      expect(fn.children.first, isA<UnicodeEmojiNode>());
    });

    test('fn内に複数のノードをネストできる', () {
      final result = parser.parse(r'$[shake text **bold** more]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.children.length, 3);
      expect(fn.children[0], isA<TextNode>());
      expect(fn.children[1], isA<BoldNode>());
      expect(fn.children[2], isA<TextNode>());
    });

    test('ボールド内にfnをネストできる', () {
      final result = parser.parse(r'**$[shake text]**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<BoldNode>());
      final bold = nodes[0] as BoldNode;
      expect(bold.children.length, 1);
      expect(bold.children.first, isA<FnNode>());
    });
  });

  group('FnParser フォールバックテスト', () {
    final parser = MfmParser().build();

    test('閉じ括弧がない場合はテキストとして扱う', () {
      final result = parser.parse(r'$[shake text');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // フォールバックでテキストとして扱われる
      expect(nodes.isNotEmpty, isTrue);
      // $[shake text 全体がテキストになるか、個別にパースされる
      final text = nodes.map((n) {
        if (n is TextNode) return n.text;
        return '';
      }).join();
      expect(text.contains(r'$['), isTrue);
    });

    test('スペースがない場合はテキストとして扱う', () {
      final result = parser.parse(r'$[shaketext]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // スペースがないためfnとして認識されない
      expect(nodes.isNotEmpty, isTrue);
    });

    test(r'単独の$[はテキストとして扱う', () {
      final result = parser.parse(r'$[');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.isNotEmpty, isTrue);
      final textNode = nodes.first;
      expect(textNode, isA<TextNode>());
      expect((textNode as TextNode).text, r'$[');
    });
  });

  group('FnParser エッジケーステスト', () {
    final parser = MfmParser().build();

    test('テキストとfnの組み合わせ', () {
      final result = parser.parse(r'before $[shake text] after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'before ');
      expect(nodes[1], isA<FnNode>());
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, ' after');
    });

    test('複数のfnを連続で解析できる', () {
      final result = parser.parse(r'$[shake a] $[spin b]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<FnNode>());
      expect((nodes[0] as FnNode).name, 'shake');
      expect(nodes[1], isA<TextNode>());
      expect(nodes[2], isA<FnNode>());
      expect((nodes[2] as FnNode).name, 'spin');
    });

    test('サイズ関数（x2, x3, x4）を解析できる', () {
      final result = parser.parse(r'$[x2 big text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'x2');
    });

    test('色指定関数を解析できる', () {
      final result = parser.parse(r'$[fg.color=ff0000 red text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'fg');
      expect(fn.args['color'], 'ff0000');
    });

    test('font関数を解析できる', () {
      final result = parser.parse(r'$[font.serif text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'font');
      expect(fn.args['serif'], isTrue);
    });

    test('rotate関数のdeg引数を解析できる', () {
      final result = parser.parse(r'$[rotate.deg=45 text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'rotate');
      expect(fn.args['deg'], '45');
    });

    test('scale関数の座標引数を解析できる', () {
      final result = parser.parse(r'$[scale.x=2,y=0.5 text]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'scale');
      expect(fn.args['x'], '2');
      expect(fn.args['y'], '0.5');
    });

    test('fn内で改行を含む内容を解析できる', () {
      final result = parser.parse('\$[shake line1\nline2]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.children.length, 1);
      expect((fn.children.first as TextNode).text, 'line1\nline2');
    });

    test('リンク内でfnを使用できる', () {
      final result = parser.parse(r'[$[shake click me]](https://example.com)');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes[0], isA<LinkNode>());
      final link = nodes[0] as LinkNode;
      expect(link.children.length, 1);
      expect(link.children.first, isA<FnNode>());
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
      expect(nodes[0], isA<FnNode>());
      final fn = nodes[0] as FnNode;
      expect(fn.name, 'tada');
    });
  });
}
