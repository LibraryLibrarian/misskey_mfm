import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../core/guards.dart';

/// 数式ブロックパーサー
///
/// LaTeX形式の数式ブロックを解析
///
/// mfm-js仕様:
/// - 形式: `\[formula\]`
/// - `\[` は行頭でなければならない
/// - `\]` は行末でなければならない
/// - 複数行の数式を含めることができる
/// - 前後の改行はトリミングされる
class MathBlockParser {
  /// 数式ブロックパーサー
  Parser<MfmNode> build() {
    final newline = char('\n');
    final open = string(r'\[');
    final close = string(r'\]');

    // 数式内容: 改行(optional) + close が出現するまでの文字列
    // mfm-js:
    // P.seq(
    //  P.notMatch(P.seq(newLine.option(), close)),
    //  P.char).select(1).many(1)
    final formulaChar = ((newline.optional() & close).not() & any()).pick(1);
    final formula = formulaChar.plus().flatten();

    // mfm-js仕様:
    // - `\[` は行頭でなければならない（入力先頭または直前が改行）
    // - `\]` は行末でなければならない（入力末尾または直後が改行）
    //
    // 構造: [lineBegin, \[, 改行?, 数式, 改行?, \], lineEnd, 後の改行?]
    final startPart = seq3(lineBegin(), open, newline.optional());
    final endPart = seq3(newline.optional(), close, lineEnd());

    return seq4(startPart, formula, endPart, newline.optional()).map4((
      start,
      formulaStr,
      end,
      trailingNewline,
    ) {
      return MathBlockNode(formulaStr);
    });
  }
}
