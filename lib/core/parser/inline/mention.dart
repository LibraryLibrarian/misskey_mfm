import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../core/guards.dart';

/// メンションパーサーで使用するホスト部分のRecord型
typedef MentionHostPart = (String, String);

/// メンションパーサーの結果のRecord型
typedef MentionRawResult = (String, String, MentionHostPart?);

/// メンションパーサー
///
/// `@user` または `@user@host` 形式のメンションを解析
/// mfm-js仕様:
/// - 直前文字が `[a-zA-Z0-9]` に一致しない場合のみ有効
/// - ユーザー名: `[A-Za-z0-9_.-]+` でマッチ後、末尾の `[.-]+` を除去
/// - ホスト名: `[A-Za-z0-9_.-]+` でマッチ後、末尾の `[.-]+` を除去
/// - 先頭が `[.-]` の場合は無効
/// - 末尾の無効文字は除去され、その部分はテキストとして扱われる

class MentionParser {
  /// 英数字パターン（直前文字チェック用）
  static final _alphanumericPattern = RegExp(r'[a-zA-Z0-9]');

  /// 末尾の無効文字パターン
  static final _trailingInvalidPattern = RegExp(r'[.-]+$');

  /// 先頭の無効文字パターン
  static final _leadingInvalidPattern = RegExp(r'^[.-]');

  /// メンションパーサーを構築
  Parser<MfmNode> build() {
    // ユーザー名/ホスト名パターン: [a-zA-Z0-9_.-]+
    // petitparserでは、ハイフンを文字として使う場合は最後に配置
    final namePattern = pattern('a-zA-Z0-9_.-').plus().flatten();

    // @user@host または @user
    // seq2/seq3を使用して型安全なRecord型を返す
    final hostPart = seq2(char('@'), namePattern);
    final mentionRaw = seq3(char('@'), namePattern, hostPart.optional());

    // カスタムパーサーで末尾処理を行う
    final mentionParser = _MentionParserImpl(mentionRaw);

    // 直前文字ガードを適用
    return withPrevCharGuard<MfmNode>(
      mentionParser,
      (prev) => prev == null || !_alphanumericPattern.hasMatch(prev),
    );
  }

  /// フォールバック付きパーサー
  ///
  /// メンションとして解析できない場合は、先頭の `@` をテキストとして扱う
  Parser<MfmNode> buildWithFallback() {
    final completeMention = build();

    // フォールバック: `@` で始まるがメンションとして解析できない場合
    final fallback = char('@').map<MfmNode>(
      TextNode.new,
    );

    return (completeMention | fallback).cast<MfmNode>();
  }

  /// 末尾の無効文字を除去
  static String? trimTrailingInvalid(String? s) {
    if (s == null) return null;
    final trimmed = s.replaceFirst(_trailingInvalidPattern, '');
    return trimmed.isEmpty ? null : trimmed;
  }

  /// 先頭が無効文字かどうか
  static bool startsWithInvalid(String s) => _leadingInvalidPattern.hasMatch(s);
}

/// メンションパーサーの実装
///
/// 末尾の無効文字を除去し、パース位置を正しく調整する
class _MentionParserImpl extends Parser<MfmNode> {
  _MentionParserImpl(this._delegate);

  final Parser<MentionRawResult> _delegate;

  @override
  Result<MfmNode> parseOn(Context context) {
    final result = _delegate.parseOn(context);
    if (result is Failure) {
      return result.failure(result.message);
    }

    // seq3のRecord型から型安全に値を取得
    final record = result.value;
    var username = record.$2;
    final hostPartRecord = record.$3;
    var host = hostPartRecord?.$2;

    // 末尾の [.-] を除去してトリム量を計算
    var trimmedFromUsername = 0;
    var trimmedFromHost = 0;

    if (host != null) {
      final originalHost = host;
      host = MentionParser.trimTrailingInvalid(host);
      if (host == null) {
        trimmedFromHost = originalHost.length;
      } else {
        trimmedFromHost = originalHost.length - host.length;
      }
    }

    // ホストがない場合のみユーザー名末尾をトリム
    if (host == null && hostPartRecord == null) {
      final originalUsername = username;
      final trimmedUsername = MentionParser.trimTrailingInvalid(username);
      if (trimmedUsername == null) {
        // ユーザー名が空になる場合は無効
        return context.failure('invalid mention: empty username after trim');
      }
      trimmedFromUsername = originalUsername.length - trimmedUsername.length;
      username = trimmedUsername;
    }

    // 先頭が [.-] なら無効
    if (MentionParser.startsWithInvalid(username)) {
      return context.failure('invalid mention: username starts with [.-]');
    }
    if (host != null && MentionParser.startsWithInvalid(host)) {
      return context.failure('invalid mention: host starts with [.-]');
    }

    // ホスト部分が無効文字のみだった場合
    if (hostPartRecord != null && host == null) {
      // @user@... の形式で、ホストが無効文字のみの場合は無効
      return context.failure('invalid mention: invalid host');
    }

    // パース位置を調整（トリムした分だけ戻す）
    final adjustedPosition =
        result.position - trimmedFromUsername - trimmedFromHost;

    final acct = host != null ? '@$username@$host' : '@$username';
    final node = MentionNode(username: username, host: host, acct: acct);

    return context.success(node, adjustedPosition);
  }

  @override
  int fastParseOn(String buffer, int position) {
    return _delegate.fastParseOn(buffer, position);
  }

  @override
  _MentionParserImpl copy() => _MentionParserImpl(_delegate.copy());
}
