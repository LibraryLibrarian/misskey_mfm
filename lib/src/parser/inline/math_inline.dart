import 'package:petitparser/petitparser.dart';

import '../../ast.dart';

/// インライン数式パーサー
///
/// LaTeX形式のインライン数式を解析する。
///
/// mfm-js仕様:
/// - 形式: `\(formula\)`
/// - 改行を含めることはできない
/// - 空の数式は無効
class MathInlineParser {
  /// インライン数式パーサー
  Parser<MfmNode> build() {
    final open = string(r'\(');
    final close = string(r'\)');
    final newline = char('\n');

    // 数式内容: \) または改行以外の文字
    // mfm-js:
    // P.seq(
    //  P.notMatch(P.alt([close, newLine])),
    //  P.char).select(1).many(1)
    final formulaChar = (close.not() & newline.not() & any()).pick(2);
    final formula = formulaChar.plus().flatten();

    // seq3で型安全なシーケンスパース
    return seq3(open, formula, close).map3((openTag, formulaStr, closeTag) {
      return MathInlineNode(formulaStr);
    });
  }
}
