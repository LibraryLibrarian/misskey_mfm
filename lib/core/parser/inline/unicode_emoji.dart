import 'package:emoji_regex/emoji_regex.dart' as emoji_regex;
import 'package:petitparser/petitparser.dart';

import '../../ast.dart';

/// Unicode絵文字パーサー
///
/// Unicode絵文字シーケンスを解析
/// mfm-js仕様:
/// - Unicodeの絵文字シーケンスを認識
/// - 肌色修飾子、ZWJ結合絵文字、国旗なども対応
///
/// emoji_regexパッケージを使用（npm emoji-regex v10.2.1ベース）
class UnicodeEmojiParser {
  /// emoji_regexパッケージから取得した正規表現
  static final RegExp _emojiRegex = emoji_regex.emojiRegex();

  /// Unicode絵文字パーサーを構築
  Parser<MfmNode> build() {
    // PatternParserを使用して正規表現でマッチ
    // PatternParserはMatchオブジェクトを返すため、group(0)で文字列を取得
    return PatternParser(_emojiRegex, 'unicode emoji').map<MfmNode>(
      (dynamic v) => UnicodeEmojiNode((v as Match).group(0)!),
    );
  }
}
