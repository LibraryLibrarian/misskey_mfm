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
      expect(nodes, [
        const BoldNode([TextNode('bold')]),
      ]);
    });

    test('基本的な斜体構文を解析できる', () {
      final result = parser.parse('*italic*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const ItalicNode([TextNode('italic')]),
      ]);
    });

    test('テキストと太字の連結を解析できる', () {
      final result = parser.parse('foo**bar**baz');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('foo'),
        const BoldNode([TextNode('bar')]),
        const TextNode('baz'),
      ]);
    });

    test('太字と斜体の組み合わせを解析できる', () {
      final result = parser.parse('**bold** *italic*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const BoldNode([TextNode('bold')]),
        const TextNode(' '),
        const ItalicNode([TextNode('italic')]),
      ]);
    });

    test('斜体内に太字をネストできる', () {
      final result = parser.parse('*italic **bold** text*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const ItalicNode([TextNode('italic ')]),
        const ItalicNode([TextNode('bold')]),
        const ItalicNode([TextNode(' text')]),
      ]);
    });

    test('太字内に斜体をネストできる', () {
      final result = parser.parse('**bold *italic* text**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const BoldNode([
          TextNode('bold '),
          ItalicNode([TextNode('italic')]),
          TextNode(' text'),
        ]),
      ]);
    });

    test('複雑なネスト構造を解析できる', () {
      final result = parser.parse('**bold *italic **nested** text* more**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const BoldNode([
          TextNode('bold '),
          ItalicNode([TextNode('italic ')]),
          ItalicNode([TextNode('nested')]),
          ItalicNode([TextNode(' text')]),
          TextNode(' more'),
        ]),
      ]);
    });

    test('プレーンテキストのみを解析できる', () {
      final result = parser.parse('plain text without formatting');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [const TextNode('plain text without formatting')]);
    });

    test('ASCII英数字以外を含む斜体構文はテキストとして扱う', () {
      final result = parser.parse('*これは斜体**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [const TextNode('*これは斜体**')]);
    });

    test('不完全な太字構文を解析できる', () {
      final result = parser.parse('**これは太字*');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 閉じ'**'が無いため全体テキストとして扱われる
      expect(nodes, [const TextNode('**これは太字*')]);
    });

    test('ASCII英数字以外を含む斜体と太字を解析できる', () {
      final result = parser.parse('*斜体**太字**');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes, [
        const TextNode('*斜体'),
        const BoldNode([TextNode('太字')]),
      ]);
    });

    // 絵文字関連のテストケース
    group('絵文字パース', () {
      test('カスタム絵文字を解析できる', () {
        final result = parser.parse(':emoji:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const EmojiCodeNode('emoji')]);
      });

      test('Unicode絵文字を解析できる', () {
        final result = parser.parse('😀');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const UnicodeEmojiNode('😀')]);
      });

      test('テキストとカスタム絵文字の混在を解析できる', () {
        final result = parser.parse('Hello :wave: World');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('Hello '),
          const EmojiCodeNode('wave'),
          const TextNode(' World'),
        ]);
      });

      test('テキストとUnicode絵文字の混在を解析できる', () {
        final result = parser.parse('Hello 👋 World');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('Hello '),
          const UnicodeEmojiNode('👋'),
          const TextNode(' World'),
        ]);
      });

      test('カスタム絵文字とUnicode絵文字の混在を解析できる', () {
        final result = parser.parse(':wave: 👋 :smile:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const EmojiCodeNode('wave'),
          const TextNode(' '),
          const UnicodeEmojiNode('👋'),
          const TextNode(' '),
          const EmojiCodeNode('smile'),
        ]);
      });

      test('太字内の絵文字を解析できる', () {
        final result = parser.parse('**:emoji: 😀**');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const BoldNode([
            EmojiCodeNode('emoji'),
            TextNode(' '),
            UnicodeEmojiNode('😀'),
          ]),
        ]);
      });

      test('絵文字コードを含む斜体構文はテキストとして扱う', () {
        final result = parser.parse('*Hello :wave:*');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('*Hello '),
          const EmojiCodeNode('wave'),
          const TextNode('*'),
        ]);
      });

      test('複数のUnicode絵文字を連続で解析できる', () {
        final result = parser.parse('😀😁😂');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const UnicodeEmojiNode('😀'),
          const UnicodeEmojiNode('😁'),
          const UnicodeEmojiNode('😂'),
        ]);
      });

      test('複数のカスタム絵文字を連続で解析できる', () {
        final result = parser.parse(':a::b::c:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const EmojiCodeNode('a'),
          const EmojiCodeNode('b'),
          const EmojiCodeNode('c'),
        ]);
      });

      test('肌色修飾子付き絵文字を解析できる', () {
        final result = parser.parse('👍🏻');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const UnicodeEmojiNode('👍🏻')]);
      });

      test('ZWJ結合絵文字を解析できる', () {
        final result = parser.parse('👨‍👩‍👧‍👦');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const UnicodeEmojiNode('👨‍👩‍👧‍👦')]);
      });

      test('国旗絵文字を解析できる', () {
        final result = parser.parse('🇯🇵');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const UnicodeEmojiNode('🇯🇵')]);
      });

      test('複雑な絵文字を含む文章を解析できる', () {
        final result = parser.parse('こんにちは :wave: 👋 **太字 :bold:**');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('こんにちは '),
          const EmojiCodeNode('wave'),
          const TextNode(' '),
          const UnicodeEmojiNode('👋'),
          const TextNode(' '),
          const BoldNode([
            TextNode('太字 '),
            EmojiCodeNode('bold'),
          ]),
        ]);
      });
    });

    // メンション関連のテストケース
    group('メンションパース', () {
      test('基本的なメンションを解析できる', () {
        final result = parser.parse('@user');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(username: 'user', acct: '@user'),
        ]);
      });

      test('リモートメンションを解析できる', () {
        final result = parser.parse('@user@misskey.io');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(
            username: 'user',
            host: 'misskey.io',
            acct: '@user@misskey.io',
          ),
        ]);
      });

      test('テキストとメンションの混在を解析できる', () {
        final result = parser.parse('Hello @user World');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('Hello '),
          const MentionNode(username: 'user', acct: '@user'),
          const TextNode(' World'),
        ]);
      });

      test('英字直後のメンションは無効（hello@user）', () {
        final result = parser.parse('hello@user');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // 全体がテキストとして扱われる
        expect(nodes, [const TextNode('hello@user')]);
      });

      test('数字直後のメンションは無効（123@user）', () {
        final result = parser.parse('123@user');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('123@user')]);
      });

      test('末尾ハイフンは除去される（@user-）', () {
        final result = parser.parse('@user- text');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(username: 'user', acct: '@user'),
          const TextNode('- text'),
        ]);
      });

      test('複数のメンションを解析できる', () {
        final result = parser.parse('@user1 @user2');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(username: 'user1', acct: '@user1'),
          const TextNode(' '),
          const MentionNode(username: 'user2', acct: '@user2'),
        ]);
      });

      test('太字内のメンションを解析できる', () {
        final result = parser.parse('**@user**');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const BoldNode([
            MentionNode(username: 'user', acct: '@user'),
          ]),
        ]);
      });

      test('メンションと絵文字の混在を解析できる', () {
        final result = parser.parse('@user :wave:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(username: 'user', acct: '@user'),
          const TextNode(' '),
          const EmojiCodeNode('wave'),
        ]);
      });
    });

    // ハッシュタグ関連のテストケース
    group('ハッシュタグパース', () {
      test('基本的なハッシュタグを解析できる', () {
        final result = parser.parse('#tag');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const HashtagNode('tag')]);
      });

      test('日本語ハッシュタグを解析できる', () {
        final result = parser.parse('#ミスキー');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const HashtagNode('ミスキー')]);
      });

      test('テキストとハッシュタグの混在を解析できる', () {
        final result = parser.parse('Hello #tag World');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('Hello '),
          const HashtagNode('tag'),
          const TextNode(' World'),
        ]);
      });

      test('英字直後のハッシュタグは無効（hello#tag）', () {
        final result = parser.parse('hello#tag');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // 全体がテキストとして扱われる
        expect(nodes, [const TextNode('hello#tag')]);
      });

      test('数字のみのハッシュタグは無効（#123）', () {
        final result = parser.parse('#123 text');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        // #はテキスト、123もテキストとして結合
        expect(nodes, [const TextNode('#123 text')]);
      });

      test('禁止文字で分離される（#tag.rest）', () {
        final result = parser.parse('#tag.rest');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('tag'),
          const TextNode('.rest'),
        ]);
      });

      test('複数のハッシュタグを解析できる', () {
        final result = parser.parse('#tag1 #tag2');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('tag1'),
          const TextNode(' '),
          const HashtagNode('tag2'),
        ]);
      });

      test('太字内のハッシュタグ（mfm-js準拠: *は禁止文字ではない）', () {
        // mfm-js準拠: * は禁止文字ではないため、#tag** がハッシュタグとして認識され、
        // 閉じ ** が見つからず太字が成立しない
        // 結果: 全体がテキストになる
        final result = parser.parse('**#tag**');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('**#tag**')]);
      });

      test('太字内のハッシュタグを解析できる（スペースで区切る場合）', () {
        // スペースで区切ることで太字内のハッシュタグが正しく解析される
        final result = parser.parse('** #tag **');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const BoldNode([
            TextNode(' '),
            HashtagNode('tag'),
            TextNode(' '),
          ]),
        ]);
      });

      test('ハッシュタグと絵文字の混在を解析できる', () {
        final result = parser.parse('#tag :wave:');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('tag'),
          const TextNode(' '),
          const EmojiCodeNode('wave'),
        ]);
      });

      test('ハッシュタグとメンションの混在を解析できる', () {
        final result = parser.parse('#tag @user');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('tag'),
          const TextNode(' '),
          const MentionNode(username: 'user', acct: '@user'),
        ]);
      });

      test('メンション直後のハッシュタグはテキストになる（@user#テスト）', () {
        // mfm.js仕様: 直前が英数字の場合、#はハッシュタグとして認識されない
        final result = parser.parse('@user#テスト');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(username: 'user', acct: '@user'),
          const TextNode('#テスト'),
        ]);
      });

      // 括弧ネスト構造のテストケース
      test('括弧ペアを含むハッシュタグを解析できる（#tag(value)）', () {
        final result = parser.parse('#tag(value)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const HashtagNode('tag(value)')]);
      });

      test('括弧ペアを含むハッシュタグとテキストの混在', () {
        final result = parser.parse('Check #foo(bar) now');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('Check '),
          const HashtagNode('foo(bar)'),
          const TextNode(' now'),
        ]);
      });

      test('外側の括弧はハッシュタグに含まれない（(#tag)）', () {
        final result = parser.parse('(#tag)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('('),
          const HashtagNode('tag'),
          const TextNode(')'),
        ]);
      });

      test('mfm.js互換: 鉤括弧で囲まれたハッシュタグ（「#foo」）', () {
        final result = parser.parse('「#foo」');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('「'),
          const HashtagNode('foo'),
          const TextNode('」'),
        ]);
      });

      test('mfm.js互換: 混合括弧（「#foo(bar)」）', () {
        final result = parser.parse('「#foo(bar)」');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('「'),
          const HashtagNode('foo(bar)'),
          const TextNode('」'),
        ]);
      });

      test('mfm.js互換: 2重ネストも有効（#tag(x(y)z) → tag(x(y)z)）', () {
        // mfm-js互換: デフォルトのnestLimitは20なので2重ネストも有効
        final result = parser.parse('#tag(x(y)z) text');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('tag(x(y)z)'),
          const TextNode(' text'),
        ]);
      });

      test('括弧が閉じていない場合は括弧で分離（#tag(value → #tag）', () {
        final result = parser.parse('#tag(value text');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('tag'),
          const TextNode('(value text'),
        ]);
      });

      // mfm-js互換: keycapとハッシュタグの相互作用
      test('mfm.js互換: with keycap number sign', () {
        // mfm.js/test/parser.ts:810-815
        // keycap number sign (#️⃣) はUnicode絵文字として認識
        // 後続の#はハッシュタグとして認識される
        final result = parser.parse('#️⃣abc123 #abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const UnicodeEmojiNode('#️⃣'),
          const TextNode('abc123 '),
          const HashtagNode('abc'),
        ]);
      });

      test('mfm.js互換: with keycap number sign 2', () {
        // mfm.js/test/parser.ts:817-822
        // 改行後のkeycap number signもUnicode絵文字として認識
        final result = parser.parse('abc\n#️⃣abc');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('abc\n'),
          const UnicodeEmojiNode('#️⃣'),
          const TextNode('abc'),
        ]);
      });

      test('mfm.js互換: ignore square bracket', () {
        // mfm.js/test/parser.ts:863-866
        // 角括弧 ] はハッシュタグに含まれない
        final result = parser.parse('#Foo]');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const HashtagNode('Foo'),
          const TextNode(']'),
        ]);
      });

      test('mfm.js互換: with brackets "()" (space before)', () {
        // mfm.js/test/parser.ts:901-905
        // 括弧内でスペース後のハッシュタグは有効
        final result = parser.parse('(bar #foo)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('(bar '),
          const HashtagNode('foo'),
          const TextNode(')'),
        ]);
      });

      test('mfm.js互換: with brackets "「」" (space before)', () {
        // mfm.js/test/parser.ts:907-911
        // 日本語括弧内でスペース後のハッシュタグは有効
        final result = parser.parse('「bar #foo」');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('「bar '),
          const HashtagNode('foo'),
          const TextNode('」'),
        ]);
      });

      test('mfm.js互換: disallow number only (with brackets)', () {
        // mfm.js/test/parser.ts:921-925
        // 括弧内でも数字のみのハッシュタグは無効
        final result = parser.parse('(#123)');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [const TextNode('(#123)')]);
      });
    });

    // 複合テストケース
    group('複合パース', () {
      test('メンション、ハッシュタグ、絵文字の混在を解析できる', () {
        final result = parser.parse('@user さんが #tag について :wave: しました');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const MentionNode(username: 'user', acct: '@user'),
          const TextNode(' さんが '),
          const HashtagNode('tag'),
          const TextNode(' について '),
          const EmojiCodeNode('wave'),
          const TextNode(' しました'),
        ]);
      });

      test('太字、メンション、ハッシュタグの組み合わせを解析できる', () {
        final result = parser.parse('**@user** posted #important');
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const BoldNode([
            MentionNode(username: 'user', acct: '@user'),
          ]),
          const TextNode(' posted '),
          const HashtagNode('important'),
        ]);
      });

      test('複雑な文章を解析できる', () {
        final result = parser.parse(
          'こんにちは @user さん！ #ミスキー で **楽しく** :wave: しましょう',
        );
        expect(result is Success, isTrue);
        final nodes = (result as Success).value as List<MfmNode>;
        expect(nodes, [
          const TextNode('こんにちは '),
          const MentionNode(username: 'user', acct: '@user'),
          const TextNode(' さん！ '),
          const HashtagNode('ミスキー'),
          const TextNode(' で '),
          const BoldNode([TextNode('楽しく')]),
          const TextNode(' '),
          const EmojiCodeNode('wave'),
          const TextNode(' しましょう'),
        ]);
      });
    });
  });
}
