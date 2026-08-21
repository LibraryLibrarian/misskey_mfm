import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import 'generated/unicode_emoji_regex.dart';

/// Unicode絵文字パーサー
///
/// Unicode絵文字シーケンスを解析
/// mfm-js仕様:
/// - Unicodeの絵文字シーケンスを認識
/// - 肌色修飾子、ZWJ結合絵文字、国旗なども対応
///
/// Unicode 17.0のRGI emoji sequenceから生成した正規表現を使用。
class UnicodeEmojiParser {
  /// Unicode 17.0のemoji-test dataから生成した正規表現。
  ///
  /// 出典と再生成手順は生成ファイルのヘッダーを参照。
  static final RegExp _emojiRegex = RegExp(
    unicodeEmojiRegexPattern,
    unicode: true,
  );

  /// Unicode絵文字パーサーを構築
  Parser<MfmNode> build() {
    // PatternParserを使用して正規表現でマッチ
    // PatternParserはMatchオブジェクトを返すため、group(0)で文字列を取得
    return PatternParser(_emojiRegex, 'unicode emoji').map<MfmNode>(
      (dynamic v) => UnicodeEmojiNode((v as Match).group(0)!),
    );
  }
}
