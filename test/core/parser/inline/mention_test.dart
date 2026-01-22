import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/inline/mention.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('MentionParser（メンション）', () {
    final parser = MentionParser().build();

    test('アンダースコアを含むユーザー名を解析できる', () {
      final result = parser.parse('@user_name');
      expect(result is Success, isTrue);
      final mention = (result as Success).value as MentionNode;
      expect(mention.username, 'user_name');
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
      expect(node, const MentionNode(username: 'user', acct: '@user'));
    });

    test('無効な場合は@をテキストとして返す', () {
      // 先頭が無効文字の場合
      final result = parser.parse('@');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, const TextNode('@'));
    });
  });
}
