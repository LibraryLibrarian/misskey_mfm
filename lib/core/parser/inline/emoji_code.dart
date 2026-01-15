import 'package:petitparser/petitparser.dart';

import '../../ast.dart';

/// カスタム絵文字コードパーサー
///
/// `:emoji_name:` 形式のカスタム絵文字を解析
/// mfm-js仕様:
/// - 内容には `[a-z0-9_+-]i` にマッチする文字のみ使用可
/// - 内容を空にすることはできない
class EmojiCodeParser {
  /// カスタム絵文字パーサーを構築
  Parser<MfmNode> build() {
    // 絵文字名: [a-zA-Z0-9_+-] が1文字以上
    final namePattern = pattern('a-zA-Z0-9_+\\-').plus().flatten();

    return (char(':') & namePattern & char(':')).map<MfmNode>((dynamic v) {
      final parts = v as List<dynamic>;
      final name = parts[1] as String;
      return EmojiCodeNode(name);
    });
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
