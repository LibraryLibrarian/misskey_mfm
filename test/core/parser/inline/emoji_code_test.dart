import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('EmojiCodeParser（カスタム絵文字）', () {
    final parser = EmojiCodeParser().build();

    test('基本的なカスタム絵文字を解析できる', () {
      final result = parser.parse(':emoji:');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<EmojiCodeNode>());
      final emoji = node as EmojiCodeNode;
      expect(emoji.name, 'emoji');
    });

    test('アンダースコアを含む絵文字名を解析できる', () {
      final result = parser.parse(':thinking_ai:');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<EmojiCodeNode>());
      expect((node as EmojiCodeNode).name, 'thinking_ai');
    });

    test('プラス記号を含む絵文字名を解析できる', () {
      final result = parser.parse(':+1:');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<EmojiCodeNode>());
      expect((node as EmojiCodeNode).name, '+1');
    });

    test('マイナス記号を含む絵文字名を解析できる', () {
      final result = parser.parse(':thumbs-up:');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<EmojiCodeNode>());
      expect((node as EmojiCodeNode).name, 'thumbs-up');
    });

    test('数字のみの絵文字名を解析できる', () {
      final result = parser.parse(':100:');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<EmojiCodeNode>());
      expect((node as EmojiCodeNode).name, '100');
    });

    test('大文字を含む絵文字名を解析できる', () {
      final result = parser.parse(':ThinkingFace:');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<EmojiCodeNode>());
      expect((node as EmojiCodeNode).name, 'ThinkingFace');
    });

    test('空の絵文字名（::）は解析失敗する', () {
      final result = parser.parse('::');
      expect(result is Failure, isTrue);
    });

    test('閉じコロンがない場合は解析失敗する', () {
      final result = parser.parse(':emoji');
      expect(result is Failure, isTrue);
    });

    test('不正な文字を含む絵文字名は部分的に解析される', () {
      // :emoji!:は:emojiまでマッチして!で止まる
      final result = parser.parse(':emoji!:');
      expect(result is Failure, isTrue);
    });

    test('スペースを含む絵文字名は解析失敗する', () {
      final result = parser.parse(':emoji name:');
      expect(result is Failure, isTrue);
    });
  });

  group('EmojiCodeParser（フォールバック付き）', () {
    final parser = EmojiCodeParser().buildWithFallback();

    test('有効な絵文字を解析できる', () {
      final result = parser.parse(':emoji:');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<EmojiCodeNode>());
    });

    test('無効な場合はコロンをテキストとして返す', () {
      final result = parser.parse(':');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<TextNode>());
      expect((node as TextNode).text, ':');
    });
  });

  group('MfmParser統合テスト（カスタム絵文字）', () {
    final parser = MfmParser().build();

    test('テキスト内のカスタム絵文字を解析できる', () {
      final result = parser.parse('Hello :wave: World');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'Hello ');
      expect(nodes[1], isA<EmojiCodeNode>());
      expect((nodes[1] as EmojiCodeNode).name, 'wave');
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, ' World');
    });

    test('複数のカスタム絵文字を解析できる', () {
      final result = parser.parse(':hello::world:');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect(nodes[0], isA<EmojiCodeNode>());
      expect((nodes[0] as EmojiCodeNode).name, 'hello');
      expect(nodes[1], isA<EmojiCodeNode>());
      expect((nodes[1] as EmojiCodeNode).name, 'world');
    });

    test('太字内のカスタム絵文字を解析できる', () {
      final result = parser.parse('**:emoji:**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<BoldNode>());
      final bold = nodes[0] as BoldNode;
      expect(bold.children.length, 1);
      expect(bold.children[0], isA<EmojiCodeNode>());
      expect((bold.children[0] as EmojiCodeNode).name, 'emoji');
    });

    test('無効なコロンはテキストとして扱われる', () {
      final result = parser.parse('Hello : World');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // コロンがテキストとして含まれる
      expect(nodes.any((n) => n is TextNode && (n.text.contains(':'))), isTrue);
    });
  });
}
