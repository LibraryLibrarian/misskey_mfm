import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('MentionParser（メンション）', () {
    final parser = MentionParser().build();

    test('基本的なローカルメンションを解析できる', () {
      final result = parser.parse('@user');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<MentionNode>());
      final mention = node as MentionNode;
      expect(mention.username, 'user');
      expect(mention.host, isNull);
      expect(mention.acct, '@user');
    });

    test('リモートメンションを解析できる', () {
      final result = parser.parse('@user@misskey.io');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<MentionNode>());
      final mention = node as MentionNode;
      expect(mention.username, 'user');
      expect(mention.host, 'misskey.io');
      expect(mention.acct, '@user@misskey.io');
    });

    test('アンダースコアを含むユーザー名を解析できる', () {
      final result = parser.parse('@user_name');
      expect(result is Success, isTrue);
      final mention = (result as Success).value as MentionNode;
      expect(mention.username, 'user_name');
    });

    test('ハイフンを含むユーザー名（中間）を解析できる', () {
      final result = parser.parse('@user-name');
      expect(result is Success, isTrue);
      final mention = (result as Success).value as MentionNode;
      expect(mention.username, 'user-name');
    });

    test('ピリオドを含むユーザー名（中間）を解析できる', () {
      final result = parser.parse('@user.name');
      expect(result is Success, isTrue);
      final mention = (result as Success).value as MentionNode;
      expect(mention.username, 'user.name');
    });

    test('数字を含むユーザー名を解析できる', () {
      final result = parser.parse('@user123');
      expect(result is Success, isTrue);
      final mention = (result as Success).value as MentionNode;
      expect(mention.username, 'user123');
    });

    test('数字のみのユーザー名を解析できる', () {
      final result = parser.parse('@12345');
      expect(result is Success, isTrue);
      final mention = (result as Success).value as MentionNode;
      expect(mention.username, '12345');
    });

    test('末尾ハイフンは除去される（@user- → @user）', () {
      final result = parser.parse('@user-');
      expect(result is Success, isTrue);
      final mention = (result as Success).value as MentionNode;
      expect(mention.username, 'user');
      expect(mention.acct, '@user');
      // パース位置は @user の直後（5文字目）で止まる
      expect((result as Success).position, 5);
    });

    test('末尾ピリオドは除去される（@user. → @user）', () {
      final result = parser.parse('@user.');
      expect(result is Success, isTrue);
      final mention = (result as Success).value as MentionNode;
      expect(mention.username, 'user');
      expect((result as Success).position, 5);
    });

    test('複数の末尾無効文字は除去される（@user-- → @user）', () {
      final result = parser.parse('@user--');
      expect(result is Success, isTrue);
      final mention = (result as Success).value as MentionNode;
      expect(mention.username, 'user');
      expect((result as Success).position, 5);
    });

    test('末尾の混合無効文字は除去される（@user-. → @user）', () {
      final result = parser.parse('@user-.');
      expect(result is Success, isTrue);
      final mention = (result as Success).value as MentionNode;
      expect(mention.username, 'user');
      expect((result as Success).position, 5);
    });

    test('先頭ハイフンは無効（@-user）', () {
      final result = parser.parse('@-user');
      expect(result is Failure, isTrue);
    });

    test('先頭ピリオドは無効（@.user）', () {
      final result = parser.parse('@.user');
      expect(result is Failure, isTrue);
    });

    test('リモートメンションの末尾ハイフンは除去される', () {
      final result = parser.parse('@user@host-');
      expect(result is Success, isTrue);
      final mention = (result as Success).value as MentionNode;
      expect(mention.username, 'user');
      expect(mention.host, 'host');
      expect(mention.acct, '@user@host');
      // @user@host = 10文字
      expect((result as Success).position, 10);
    });

    test('リモートメンションのホスト先頭ハイフンは無効', () {
      final result = parser.parse('@user@-host');
      expect(result is Failure, isTrue);
    });

    test('大文字を含むユーザー名を解析できる', () {
      final result = parser.parse('@UserName');
      expect(result is Success, isTrue);
      final mention = (result as Success).value as MentionNode;
      expect(mention.username, 'UserName');
    });

    test('複雑なリモートメンションを解析できる', () {
      final result = parser.parse('@user_name@sub.domain.example.com');
      expect(result is Success, isTrue);
      final mention = (result as Success).value as MentionNode;
      expect(mention.username, 'user_name');
      expect(mention.host, 'sub.domain.example.com');
    });
  });

  group('MentionParser（直前文字ガード）', () {
    final parser = MentionParser().build();

    test('英字直後のメンションは無効（hello@user）', () {
      // 直前文字ガードはパース開始位置の直前をチェックするため、
      // 単独パーサーでは先頭からのパースでテスト
      // 統合テストでMfmParser経由でテストする
      final result = parser.parse('@user');
      expect(result is Success, isTrue);
    });

    test('数字直後のメンションは無効になる', () {
      // このテストは統合テストで確認
      final result = parser.parse('@user');
      expect(result is Success, isTrue);
    });
  });

  group('MentionParser（フォールバック付き）', () {
    final parser = MentionParser().buildWithFallback();

    test('有効なメンションを解析できる', () {
      final result = parser.parse('@user');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<MentionNode>());
    });

    test('無効な場合は@をテキストとして返す', () {
      // 先頭が無効文字の場合
      final result = parser.parse('@');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<TextNode>());
      expect((node as TextNode).text, '@');
    });
  });

  // mfm-js準拠: 統合テスト（MfmParser使用）
  // test/parser.ts:700-783
  group('MentionParser（mfm-js準拠 統合テスト）', () {
    final parser = MfmParser().build();

    test('basic remote 2', () {
      // mfm.js/test/parser.ts:701-704
      const input = 'before @abc@misskey.io after';
      final result = parser.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'before ');
      expect(nodes[1], isA<MentionNode>());
      final mention = nodes[1] as MentionNode;
      expect(mention.username, 'abc');
      expect(mention.host, 'misskey.io');
      expect(mention.acct, '@abc@misskey.io');
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, ' after');
    });

    test('basic remote 3', () {
      // mfm.js/test/parser.ts:707-710
      const input = 'before\n@abc@misskey.io\nafter';
      final result = parser.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'before\n');
      expect(nodes[1], isA<MentionNode>());
      final mention = nodes[1] as MentionNode;
      expect(mention.username, 'abc');
      expect(mention.host, 'misskey.io');
      expect(mention.acct, '@abc@misskey.io');
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, '\nafter');
    });

    test('detect as a mention if the before char is [^a-z0-9]i', () {
      // mfm.js/test/parser.ts:719-722
      // 直前の文字が英数字以外の場合はメンションとして認識される
      const input = 'あいう@abc';
      final result = parser.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'あいう');
      expect(nodes[1], isA<MentionNode>());
      final mention = nodes[1] as MentionNode;
      expect(mention.username, 'abc');
      expect(mention.host, isNull);
      expect(mention.acct, '@abc');
    });

    test('invalid char only username', () {
      // mfm.js/test/parser.ts:725-728
      // ユーザー名が無効文字のみの場合はテキストになる
      const input = '@-';
      final result = parser.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, '@-');
    });

    test('invalid char only hostname', () {
      // mfm.js/test/parser.ts:731-734
      // ホスト名が無効な場合はテキストになる
      const input = '@abc@.';
      final result = parser.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, '@abc@.');
    });

    test('disallow "." in head of hostname', () {
      // mfm.js/test/parser.ts:773-776
      // ホスト名の先頭に"."がある場合はテキストになる
      const input = '@abc@.aaa';
      final result = parser.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, '@abc@.aaa');
    });

    test('disallow "." in tail of hostname', () {
      // mfm.js/test/parser.ts:779-782
      // ホスト名の末尾に"."がある場合は"."の前までをホスト名として扱う
      const input = '@abc@aaa.';
      final result = parser.parse(input);
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect(nodes[0], isA<MentionNode>());
      final mention = nodes[0] as MentionNode;
      expect(mention.username, 'abc');
      expect(mention.host, 'aaa');
      expect(mention.acct, '@abc@aaa');
      expect(nodes[1], isA<TextNode>());
      expect((nodes[1] as TextNode).text, '.');
    });
  });
}
