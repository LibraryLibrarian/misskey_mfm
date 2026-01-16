import 'package:petitparser/petitparser.dart';

import '../../ast.dart';

/// コードブロックパーサー
///
/// 三連バッククォートで囲まれたコードブロックを解析する。
///
/// 形式: 開始フェンス + 言語指定（任意） + 改行 + 本文 + 改行 + 終了フェンス
///
/// - `lang` は無視（ハイライト等は行わないため破棄）
/// - 終了フェンスは行頭の三連バッククォートである必要がある
/// - 内容中の三連バッククォートは無視（終了フェンス直前の改行+三連バッククォートのみが終わり）
class CodeBlockParser {
  /// コードブロックの基本パーサー
  Parser<MfmNode> build() {
    final fence = string('```');
    final newline = char('\n');

    // 言語指定 (改行まで) - 破棄対象
    final langPart = (newline.not() & any()).star().flatten();

    // 開始: ``` + lang + \n → 言語文字列にマップするが後段で破棄
    final start = seq3(fence, langPart, newline).map((result) => result.$2);

    // 内容: 次の "\n```" まで
    final content = any().starLazy(string('\n```')).flatten();

    // 終了: \n``` （末尾の```のみを消費）
    final end = string('\n') & fence;

    return seq3(start, content, end).map((result) {
      final lang = result.$1;
      final code = result.$2;
      return CodeBlockNode(
        code: code,
        language: lang.isEmpty ? null : lang,
      );
    });
  }
}
