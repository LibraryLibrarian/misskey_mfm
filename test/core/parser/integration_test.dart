import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('MfmParser（統合テスト）', () {
    final parser = MfmParser().build();

    test('基本的な太字構文を解析できる', () {
      final result = parser.parse('**bold**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes.first, isA<BoldNode>());
      final bold = nodes.first as BoldNode;
      expect(bold.children.length, 1);
      expect(bold.children.first, isA<TextNode>());
      expect((bold.children.first as TextNode).text, 'bold');
    });

    test('基本的な斜体構文を解析できる', () {
      final result = parser.parse('*italic*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes.first, isA<ItalicNode>());
      final italic = nodes.first as ItalicNode;
      expect(italic.children.length, 1);
      expect(italic.children.first, isA<TextNode>());
      expect((italic.children.first as TextNode).text, 'italic');
    });

    test('テキストと太字の連結を解析できる', () {
      final result = parser.parse('foo**bar**baz');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'foo');
      expect(nodes[1], isA<BoldNode>());
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, 'baz');
    });

    test('太字と斜体の組み合わせを解析できる', () {
      final result = parser.parse('**bold** *italic*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<BoldNode>());
      expect(nodes[1], isA<TextNode>());
      expect((nodes[1] as TextNode).text, ' ');
      expect(nodes[2], isA<ItalicNode>());
    });

    test('斜体内に太字をネストできる', () {
      final result = parser.parse('*italic **bold** text*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<ItalicNode>());
      expect(nodes[1], isA<ItalicNode>());
      expect(nodes[2], isA<ItalicNode>());
    });

    test('太字内に斜体をネストできる', () {
      final result = parser.parse('**bold *italic* text**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<BoldNode>());
      final bold = nodes[0] as BoldNode;
      expect(bold.children.length, 3);
      expect(bold.children[0], isA<TextNode>());
      expect((bold.children[0] as TextNode).text, 'bold ');
      expect(bold.children[1], isA<ItalicNode>());
      expect(bold.children[2], isA<TextNode>());
      expect((bold.children[2] as TextNode).text, ' text');
    });

    test('複雑なネスト構造を解析できる', () {
      final result = parser.parse('**bold *italic **nested** text* more**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<BoldNode>());
      final bold = nodes[0] as BoldNode;
      expect(bold.children.first, isA<TextNode>());
      expect((bold.children.first as TextNode).text, 'bold ');
      expect(bold.children.last, isA<TextNode>());
      expect((bold.children.last as TextNode).text, ' more');
      // 中間に少なくとも1つ以上の斜体が存在する
      expect(bold.children.whereType<ItalicNode>().isNotEmpty, isTrue);
    });

    test('プレーンテキストのみを解析できる', () {
      final result = parser.parse('plain text without formatting');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'plain text without formatting');
    });

    test('不完全な斜体構文を解析できる', () {
      final result = parser.parse('*これは斜体**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 斜体+余剰'*'テキストの2ノードになる
      expect(nodes.length, 2);
      expect(nodes[0], isA<ItalicNode>());
      expect((nodes[0] as ItalicNode).children.first, isA<TextNode>());
      expect(
        ((nodes[0] as ItalicNode).children.first as TextNode).text,
        'これは斜体',
      );
      expect(nodes[1], isA<TextNode>());
      expect((nodes[1] as TextNode).text, '*');
    });

    test('不完全な太字構文を解析できる', () {
      final result = parser.parse('**これは太字*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 閉じ'**'が無いため全体テキストとして扱われる
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, '**これは太字*');
    });

    test('複雑な不完全な構文を解析できる', () {
      final result = parser.parse('*斜体**太字**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 斜体('斜体') + 斜体('太字') + 余剰'*' の3ノード
      expect(nodes.length, 3);
      expect(nodes[0], isA<ItalicNode>());
      expect(((nodes[0] as ItalicNode).children.first as TextNode).text, '斜体');
      expect(nodes[1], isA<ItalicNode>());
      expect(((nodes[1] as ItalicNode).children.first as TextNode).text, '太字');
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, '*');
    });

    // 絵文字関連のテストケース
    group('絵文字パース', () {
      test('カスタム絵文字を解析できる', () {
        final result = parser.parse(':emoji:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<EmojiCodeNode>());
        expect((nodes[0] as EmojiCodeNode).name, 'emoji');
      });

      test('Unicode絵文字を解析できる', () {
        final result = parser.parse('😀');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<UnicodeEmojiNode>());
        expect((nodes[0] as UnicodeEmojiNode).emoji, '😀');
      });

      test('テキストとカスタム絵文字の混在を解析できる', () {
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

      test('テキストとUnicode絵文字の混在を解析できる', () {
        final result = parser.parse('Hello 👋 World');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'Hello ');
        expect(nodes[1], isA<UnicodeEmojiNode>());
        expect((nodes[1] as UnicodeEmojiNode).emoji, '👋');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, ' World');
      });

      test('カスタム絵文字とUnicode絵文字の混在を解析できる', () {
        final result = parser.parse(':wave: 👋 :smile:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 5);
        expect(nodes[0], isA<EmojiCodeNode>());
        expect((nodes[0] as EmojiCodeNode).name, 'wave');
        expect(nodes[1], isA<TextNode>());
        expect(nodes[2], isA<UnicodeEmojiNode>());
        expect(nodes[3], isA<TextNode>());
        expect(nodes[4], isA<EmojiCodeNode>());
        expect((nodes[4] as EmojiCodeNode).name, 'smile');
      });

      test('太字内の絵文字を解析できる', () {
        final result = parser.parse('**:emoji: 😀**');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<BoldNode>());
        final bold = nodes[0] as BoldNode;
        expect(bold.children.length, 3);
        expect(bold.children[0], isA<EmojiCodeNode>());
        expect(bold.children[1], isA<TextNode>());
        expect(bold.children[2], isA<UnicodeEmojiNode>());
      });

      test('斜体内の絵文字を解析できる', () {
        final result = parser.parse('*Hello :wave:*');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<ItalicNode>());
        final italic = nodes[0] as ItalicNode;
        expect(italic.children.any((n) => n is EmojiCodeNode), isTrue);
      });

      test('複数のUnicode絵文字を連続で解析できる', () {
        final result = parser.parse('😀😁😂');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes.every((n) => n is UnicodeEmojiNode), isTrue);
      });

      test('複数のカスタム絵文字を連続で解析できる', () {
        final result = parser.parse(':a::b::c:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes.every((n) => n is EmojiCodeNode), isTrue);
      });

      test('肌色修飾子付き絵文字を解析できる', () {
        final result = parser.parse('👍🏻');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<UnicodeEmojiNode>());
        expect((nodes[0] as UnicodeEmojiNode).emoji, '👍🏻');
      });

      test('ZWJ結合絵文字を解析できる', () {
        final result = parser.parse('👨‍👩‍👧‍👦');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<UnicodeEmojiNode>());
        expect((nodes[0] as UnicodeEmojiNode).emoji, '👨‍👩‍👧‍👦');
      });

      test('国旗絵文字を解析できる', () {
        final result = parser.parse('🇯🇵');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<UnicodeEmojiNode>());
        expect((nodes[0] as UnicodeEmojiNode).emoji, '🇯🇵');
      });

      test('複雑な絵文字を含む文章を解析できる', () {
        final result = parser.parse('こんにちは :wave: 👋 **太字 :bold:**');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.any((n) => n is EmojiCodeNode), isTrue);
        expect(nodes.any((n) => n is UnicodeEmojiNode), isTrue);
        expect(nodes.any((n) => n is BoldNode), isTrue);
      });
    });

    // メンション関連のテストケース
    group('メンションパース', () {
      test('基本的なメンションを解析できる', () {
        final result = parser.parse('@user');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<MentionNode>());
        expect((nodes[0] as MentionNode).username, 'user');
        expect((nodes[0] as MentionNode).host, isNull);
      });

      test('リモートメンションを解析できる', () {
        final result = parser.parse('@user@misskey.io');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<MentionNode>());
        final mention = nodes[0] as MentionNode;
        expect(mention.username, 'user');
        expect(mention.host, 'misskey.io');
      });

      test('テキストとメンションの混在を解析できる', () {
        final result = parser.parse('Hello @user World');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'Hello ');
        expect(nodes[1], isA<MentionNode>());
        expect((nodes[1] as MentionNode).username, 'user');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, ' World');
      });

      test('英字直後のメンションは無効（hello@user）', () {
        final result = parser.parse('hello@user');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // 全体がテキストとして扱われる
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'hello@user');
      });

      test('数字直後のメンションは無効（123@user）', () {
        final result = parser.parse('123@user');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '123@user');
      });

      test('末尾ハイフンは除去される（@user-）', () {
        final result = parser.parse('@user- text');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 2);
        expect(nodes[0], isA<MentionNode>());
        expect((nodes[0] as MentionNode).username, 'user');
        expect(nodes[1], isA<TextNode>());
        expect((nodes[1] as TextNode).text, '- text');
      });

      test('複数のメンションを解析できる', () {
        final result = parser.parse('@user1 @user2');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<MentionNode>());
        expect(nodes[1], isA<TextNode>());
        expect(nodes[2], isA<MentionNode>());
      });

      test('太字内のメンションを解析できる', () {
        final result = parser.parse('**@user**');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<BoldNode>());
        final bold = nodes[0] as BoldNode;
        expect(bold.children.length, 1);
        expect(bold.children[0], isA<MentionNode>());
      });

      test('メンションと絵文字の混在を解析できる', () {
        final result = parser.parse('@user :wave:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<MentionNode>());
        expect(nodes[1], isA<TextNode>());
        expect(nodes[2], isA<EmojiCodeNode>());
      });
    });

    // ハッシュタグ関連のテストケース
    group('ハッシュタグパース', () {
      test('基本的なハッシュタグを解析できる', () {
        final result = parser.parse('#tag');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<HashtagNode>());
        expect((nodes[0] as HashtagNode).hashtag, 'tag');
      });

      test('日本語ハッシュタグを解析できる', () {
        final result = parser.parse('#ミスキー');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<HashtagNode>());
        expect((nodes[0] as HashtagNode).hashtag, 'ミスキー');
      });

      test('テキストとハッシュタグの混在を解析できる', () {
        final result = parser.parse('Hello #tag World');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'Hello ');
        expect(nodes[1], isA<HashtagNode>());
        expect((nodes[1] as HashtagNode).hashtag, 'tag');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, ' World');
      });

      test('英字直後のハッシュタグは無効（hello#tag）', () {
        final result = parser.parse('hello#tag');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // 全体がテキストとして扱われる
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'hello#tag');
      });

      test('数字のみのハッシュタグは無効（#123）', () {
        final result = parser.parse('#123 text');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // #はテキスト、123もテキストとして結合
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
      });

      test('禁止文字で分離される（#tag.rest）', () {
        final result = parser.parse('#tag.rest');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 2);
        expect(nodes[0], isA<HashtagNode>());
        expect((nodes[0] as HashtagNode).hashtag, 'tag');
        expect(nodes[1], isA<TextNode>());
        expect((nodes[1] as TextNode).text, '.rest');
      });

      test('複数のハッシュタグを解析できる', () {
        final result = parser.parse('#tag1 #tag2');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<HashtagNode>());
        expect(nodes[1], isA<TextNode>());
        expect(nodes[2], isA<HashtagNode>());
      });

      test('太字内のハッシュタグ（mfm-js準拠: *は禁止文字ではない）', () {
        // mfm-js準拠: * は禁止文字ではないため、#tag** がハッシュタグとして認識され、
        // 閉じ ** が見つからず太字が成立しない
        // 結果: 全体がテキストになる
        final result = parser.parse('**#tag**');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '**#tag**');
      });

      test('太字内のハッシュタグを解析できる（スペースで区切る場合）', () {
        // スペースで区切ることで太字内のハッシュタグが正しく解析される
        final result = parser.parse('** #tag **');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<BoldNode>());
        final bold = nodes[0] as BoldNode;
        expect(bold.children.any((n) => n is HashtagNode), isTrue);
      });

      test('ハッシュタグと絵文字の混在を解析できる', () {
        final result = parser.parse('#tag :wave:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<HashtagNode>());
        expect(nodes[1], isA<TextNode>());
        expect(nodes[2], isA<EmojiCodeNode>());
      });

      test('ハッシュタグとメンションの混在を解析できる', () {
        final result = parser.parse('#tag @user');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<HashtagNode>());
        expect(nodes[1], isA<TextNode>());
        expect(nodes[2], isA<MentionNode>());
      });

      test('メンション直後のハッシュタグはテキストになる（@user#テスト）', () {
        // mfm.js仕様: 直前が英数字の場合、#はハッシュタグとして認識されない
        final result = parser.parse('@user#テスト');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 2);
        expect(nodes[0], isA<MentionNode>());
        expect((nodes[0] as MentionNode).username, 'user');
        expect(nodes[1], isA<TextNode>());
        expect((nodes[1] as TextNode).text, '#テスト');
      });

      // 括弧ネスト構造のテストケース
      test('括弧ペアを含むハッシュタグを解析できる（#tag(value)）', () {
        final result = parser.parse('#tag(value)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<HashtagNode>());
        expect((nodes[0] as HashtagNode).hashtag, 'tag(value)');
      });

      test('括弧ペアを含むハッシュタグとテキストの混在', () {
        final result = parser.parse('Check #foo(bar) now');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'Check ');
        expect(nodes[1], isA<HashtagNode>());
        expect((nodes[1] as HashtagNode).hashtag, 'foo(bar)');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, ' now');
      });

      test('外側の括弧はハッシュタグに含まれない（(#tag)）', () {
        final result = parser.parse('(#tag)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '(');
        expect(nodes[1], isA<HashtagNode>());
        expect((nodes[1] as HashtagNode).hashtag, 'tag');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, ')');
      });

      test('mfm.js互換: 鉤括弧で囲まれたハッシュタグ（「#foo」）', () {
        final result = parser.parse('「#foo」');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '「');
        expect(nodes[1], isA<HashtagNode>());
        expect((nodes[1] as HashtagNode).hashtag, 'foo');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, '」');
      });

      test('mfm.js互換: 混合括弧（「#foo(bar)」）', () {
        final result = parser.parse('「#foo(bar)」');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '「');
        expect(nodes[1], isA<HashtagNode>());
        expect((nodes[1] as HashtagNode).hashtag, 'foo(bar)');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, '」');
      });

      test('mfm.js互換: 2重ネストも有効（#tag(x(y)z) → tag(x(y)z)）', () {
        // mfm-js互換: デフォルトのnestLimitは20なので2重ネストも有効
        final result = parser.parse('#tag(x(y)z) text');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 2);
        expect(nodes[0], isA<HashtagNode>());
        expect((nodes[0] as HashtagNode).hashtag, 'tag(x(y)z)');
        expect(nodes[1], isA<TextNode>());
        expect((nodes[1] as TextNode).text, ' text');
      });

      test('括弧が閉じていない場合は括弧で分離（#tag(value → #tag）', () {
        final result = parser.parse('#tag(value text');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 2);
        expect(nodes[0], isA<HashtagNode>());
        expect((nodes[0] as HashtagNode).hashtag, 'tag');
        expect(nodes[1], isA<TextNode>());
        expect((nodes[1] as TextNode).text, '(value text');
      });

      // mfm-js互換: keycapとハッシュタグの相互作用
      test('mfm.js互換: with keycap number sign', () {
        // mfm.js/test/parser.ts:810-815
        // keycap number sign (#️⃣) はUnicode絵文字として認識
        // 後続の#はハッシュタグとして認識される
        final result = parser.parse('#️⃣abc123 #abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<UnicodeEmojiNode>());
        expect((nodes[0] as UnicodeEmojiNode).emoji, '#️⃣');
        expect(nodes[1], isA<TextNode>());
        expect((nodes[1] as TextNode).text, 'abc123 ');
        expect(nodes[2], isA<HashtagNode>());
        expect((nodes[2] as HashtagNode).hashtag, 'abc');
      });

      test('mfm.js互換: with keycap number sign 2', () {
        // mfm.js/test/parser.ts:817-822
        // 改行後のkeycap number signもUnicode絵文字として認識
        final result = parser.parse('abc\n#️⃣abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'abc\n');
        expect(nodes[1], isA<UnicodeEmojiNode>());
        expect((nodes[1] as UnicodeEmojiNode).emoji, '#️⃣');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, 'abc');
      });

      test('mfm.js互換: ignore square bracket', () {
        // mfm.js/test/parser.ts:863-866
        // 角括弧 ] はハッシュタグに含まれない
        final result = parser.parse('#Foo]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 2);
        expect(nodes[0], isA<HashtagNode>());
        expect((nodes[0] as HashtagNode).hashtag, 'Foo');
        expect(nodes[1], isA<TextNode>());
        expect((nodes[1] as TextNode).text, ']');
      });

      test('mfm.js互換: with brackets "()" (space before)', () {
        // mfm.js/test/parser.ts:901-905
        // 括弧内でスペース後のハッシュタグは有効
        final result = parser.parse('(bar #foo)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '(bar ');
        expect(nodes[1], isA<HashtagNode>());
        expect((nodes[1] as HashtagNode).hashtag, 'foo');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, ')');
      });

      test('mfm.js互換: with brackets "「」" (space before)', () {
        // mfm.js/test/parser.ts:907-911
        // 日本語括弧内でスペース後のハッシュタグは有効
        final result = parser.parse('「bar #foo」');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 3);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '「bar ');
        expect(nodes[1], isA<HashtagNode>());
        expect((nodes[1] as HashtagNode).hashtag, 'foo');
        expect(nodes[2], isA<TextNode>());
        expect((nodes[2] as TextNode).text, '」');
      });

      test('mfm.js互換: disallow number only (with brackets)', () {
        // mfm.js/test/parser.ts:921-925
        // 括弧内でも数字のみのハッシュタグは無効
        final result = parser.parse('(#123)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, '(#123)');
      });
    });

    // 複合テストケース
    group('複合パース', () {
      test('メンション、ハッシュタグ、絵文字の混在を解析できる', () {
        final result = parser.parse('@user さんが #tag について :wave: しました');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.any((n) => n is MentionNode), isTrue);
        expect(nodes.any((n) => n is HashtagNode), isTrue);
        expect(nodes.any((n) => n is EmojiCodeNode), isTrue);
      });

      test('太字、メンション、ハッシュタグの組み合わせを解析できる', () {
        final result = parser.parse('**@user** posted #important');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes[0], isA<BoldNode>());
        expect(nodes.any((n) => n is HashtagNode), isTrue);
      });

      test('複雑な文章を解析できる', () {
        final result = parser.parse(
          'こんにちは @user さん！ #ミスキー で **楽しく** :wave: しましょう',
        );
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.any((n) => n is MentionNode), isTrue);
        expect(nodes.any((n) => n is HashtagNode), isTrue);
        expect(nodes.any((n) => n is BoldNode), isTrue);
        expect(nodes.any((n) => n is EmojiCodeNode), isTrue);
      });
    });
  });
}
