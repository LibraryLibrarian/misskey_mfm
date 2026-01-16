import 'package:petitparser/petitparser.dart';

import '../../ast.dart';

/// インラインコード構文パーサー
///
/// バッククォート ` で囲まれた1行のコードを解析する
/// 改行およびアキュートアクセント（´ U+00B4）を内容に含む場合は無効として扱う
class InlineCodeParser {
  /// インラインコード（` ... `）の基本パーサー
  Parser<MfmNode> build() {
    final backtick = char('`');
    final notNewlineOrAcute =
        char('\n').not() & char('´').not() & backtick.not() & any();
    final inner = notNewlineOrAcute.starLazy(backtick).flatten();

    return seq3(backtick, inner, backtick).map((result) {
      final code = result.$2;
      return InlineCodeNode(code);
    });
  }

  /// フォールバック付き
  ///
  /// マッチしない場合、先頭の "`" 以降の全文をテキストとして返す
  Parser<MfmNode> buildWithFallback() {
    final complete = build();
    final fallback = (char('`') & any().star()).flatten().map<MfmNode>(
      TextNode.new,
    );
    return (complete | fallback).cast<MfmNode>();
  }
}
