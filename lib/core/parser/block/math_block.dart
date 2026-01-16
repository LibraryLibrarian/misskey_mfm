import 'package:petitparser/petitparser.dart';

import '../../ast.dart';

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

    // 行末判定（改行または入力終端）
    final lineEnd = newline | endOfInput();

    // 数式内容: 改行(optional) + close が出現するまでの文字列
    // mfm-js:
    // P.seq(
    //  P.notMatch(P.seq(newLine.option(), close)),
    //  P.char).select(1).many(1)
    final formulaChar = ((newline.optional() & close).not() & any()).pick(1);
    final formula = formulaChar.plus().flatten();

    // 構造: [前の改行?, \[, 改行?, 数式, 改行?, \], 行末?, 後の改行?]
    // seq2でネストして論理的にグループ化
    // 開始部: 前の改行? + \[ + 改行?
    final startPart = seq3(newline.optional(), open, newline.optional());
    // 終了部: 改行? + \] + 行末? + 後の改行?
    final endPart = seq4(
      newline.optional(),
      close,
      lineEnd.optional(),
      newline.optional(),
    );

    return seq3(startPart, formula, endPart).map3((_, formulaStr, _) {
      return MathBlockNode(formulaStr);
    });
  }
}
