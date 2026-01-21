import 'package:petitparser/petitparser.dart';

import '../../ast.dart';

/// カスタム絵文字コードパーサー
///
/// `:emoji_name:` 形式のカスタム絵文字を解析
/// mfm-js仕様:
/// - 内容には `[a-z0-9_+-]i` にマッチする文字のみ使用可
/// - 内容を空にすることはできない
/// - 前後が英数字でないこと（行頭/行末は許可）
class EmojiCodeParser {
  /// カスタム絵文字パーサーを構築
  ///
  /// mfm-js準拠: 前後文字チェック付き
  Parser<MfmNode> build() {
    return _EmojiCodeParserImpl();
  }

  /// フォールバック付きパーサー
  ///
  /// カスタム絵文字として解析できない場合は、先頭の `:` をテキストとして扱う
  Parser<MfmNode> buildWithFallback() {
    final completeEmoji = build();

    // フォールバック: `:` で始まるが絵文字として解析できない場合
    final fallback = char(':').map<MfmNode>(
      (dynamic c) => TextNode(c as String),
    );

    return (completeEmoji | fallback).cast<MfmNode>();
  }
}

/// カスタム絵文字パーサーの実装
///
/// mfm-js仕様に準拠:
/// - 前: 行頭または非英数字
/// - 後: 行末または非英数字
class _EmojiCodeParserImpl extends Parser<MfmNode> {
  /// 英数字パターン
  static final _alphanumericPattern = RegExp(r'[a-zA-Z0-9]');

  @override
  Result<MfmNode> parseOn(Context context) {
    final buffer = context.buffer;
    var position = context.position;

    // 前方チェック: 行頭または非英数字
    if (position > 0) {
      final prevChar = buffer[position - 1];
      if (_alphanumericPattern.hasMatch(prevChar)) {
        return context.failure('prev char is alphanumeric');
      }
    }

    // `:` で始まることを確認
    if (position >= buffer.length || buffer[position] != ':') {
      return context.failure('expected :');
    }
    position++;

    // 絵文字名を読み取る
    final nameStart = position;
    while (position < buffer.length) {
      final c = buffer[position];
      // 絵文字名に使用可能な文字: [a-zA-Z0-9_+-]
      if (_isValidNameChar(c)) {
        position++;
      } else {
        break;
      }
    }

    // 絵文字名が空の場合は失敗
    if (position == nameStart) {
      return context.failure('empty emoji name');
    }

    final name = buffer.substring(nameStart, position);

    // 閉じ `:` を確認
    if (position >= buffer.length || buffer[position] != ':') {
      return context.failure('expected closing :');
    }
    position++;

    // 後方チェック: 行末または非英数字
    if (position < buffer.length) {
      final nextChar = buffer[position];
      if (_alphanumericPattern.hasMatch(nextChar)) {
        return context.failure('next char is alphanumeric');
      }
    }

    return context.success(EmojiCodeNode(name), position);
  }

  /// 絵文字名に使用可能な文字かどうか
  bool _isValidNameChar(String c) {
    final code = c.codeUnitAt(0);
    // a-z
    if (code >= 0x61 && code <= 0x7A) return true;
    // A-Z
    if (code >= 0x41 && code <= 0x5A) return true;
    // 0-9
    if (code >= 0x30 && code <= 0x39) return true;
    // _ + -
    if (c == '_' || c == '+' || c == '-') return true;
    return false;
  }

  @override
  int fastParseOn(String buffer, int position) {
    final result = parseOn(Context(buffer, position));
    return result is Success ? result.position : -1;
  }

  @override
  Parser<MfmNode> copy() => _EmojiCodeParserImpl();
}
