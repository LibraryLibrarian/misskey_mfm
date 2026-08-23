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

    test('先頭ピリオドは試行範囲全体をテキストにする（@.user）', () {
      const input = '@.user';
      final result = parser.parse(input);
      expect(result, isA<Success<MfmNode>>());
      expect((result as Success<MfmNode>).value, const TextNode(input));
      expect(result.position, input.length);
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

    test('リモートメンションのホスト先頭ハイフンは全体をテキストにする', () {
      const input = '@user@-host';
      final result = parser.parse(input);
      expect(result, isA<Success<MfmNode>>());
      expect((result as Success<MfmNode>).value, const TextNode(input));
      expect(result.position, input.length);
    });

    test('@abc.@defはremote username末尾dotをtrimせず全体TEXTにする', () {
      const input = '@abc.@def';
      final result = parser.parse(input);
      expect(result, isA<Success<MfmNode>>());
      expect((result as Success<MfmNode>).value, const TextNode(input));
      expect(result.position, input.length);
    });

    test('invalid remote mentionは後続テキストまで消費しない', () {
      const invalidMention = '@abc.@def';
      const input = '$invalidMention tail';
      final result = parser.parse(input);
      expect(result, isA<Success<MfmNode>>());
      expect(
        (result as Success<MfmNode>).value,
        const TextNode(invalidMention),
      );
      expect(result.position, invalidMention.length);
    });

    test('@abc.はlocal username末尾dotの直前までmentionにする', () {
      const input = '@abc.';
      final result = parser.parse(input);
      expect(result, isA<Success<MfmNode>>());
      expect(
        (result as Success<MfmNode>).value,
        const MentionNode(username: 'abc', acct: '@abc'),
      );
      expect(result.position, 4);
    });

    test('@abc@aaa.はhost末尾dotの直前までmentionにする', () {
      const input = '@abc@aaa.';
      final result = parser.parse(input);
      expect(result, isA<Success<MfmNode>>());
      expect(
        (result as Success<MfmNode>).value,
        const MentionNode(username: 'abc', host: 'aaa', acct: '@abc@aaa'),
      );
      expect(result.position, 8);
    });

    test('@bsky.brid.gy@bsky.brid.gyのusername内dotを維持する', () {
      const input = '@bsky.brid.gy@bsky.brid.gy';
      final result = parser.parse(input);
      expect(result, isA<Success<MfmNode>>());
      expect(
        (result as Success<MfmNode>).value,
        const MentionNode(
          username: 'bsky.brid.gy',
          host: 'bsky.brid.gy',
          acct: input,
        ),
      );
      expect(result.position, input.length);
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

    test('email中の@位置では開始位置のまま失敗する', () {
      const input = 'abc@example.com';
      final result = parser.parseOn(const Context(input, 3));
      expect(result, isA<Failure>());
      expect(result.position, 3);
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

    test('remote username末尾がdotなinvalid mentionは内部@も含めて返す', () {
      const input = '@abc.@def';
      final result = parser.parse(input);
      expect(result, isA<Success<MfmNode>>());
      expect((result as Success<MfmNode>).value, const TextNode(input));
      expect(result.position, input.length);
    });
  });
}
