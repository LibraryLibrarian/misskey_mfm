import 'package:petitparser/petitparser.dart';
import '../../ast.dart';

/// テキスト処理の共通ユーティリティ
class TextParser {
  /// テキストノードのパーサー
  ///
  /// 指定された文字列で始まらない任意の文字列を解析する
  ///
  /// [excludeStart] 除外する開始文字列
  /// 戻り値: テキストノードを解析するパーサー
  static Parser<MfmNode> textNode(String excludeStart) {
    final Parser notExcludeStart = (string(excludeStart).not() & any())
        .plus()
        .flatten();
    return notExcludeStart.map<MfmNode>(
      (dynamic value) => TextNode(value as String),
    );
  }

  /// 任意の文字列を解析するテキストノードパーサー
  ///
  /// 戻り値: 任意の文字列を解析するパーサー
  static Parser<MfmNode> anyText() {
    return any().plus().flatten().map<MfmNode>(
      (dynamic value) => TextNode(value as String),
    );
  }
}
