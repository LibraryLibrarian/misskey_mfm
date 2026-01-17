import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../core/guards.dart';

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
  ///
  /// - 開始の ``` は行頭でなければならない（lineBegin）
  /// - 終了の ``` は行末でなければならない（lineEnd）
  Parser<MfmNode> build() {
    final fence = string('```');
    final newline = char('\n');

    // 言語指定 (改行まで)
    final langPart = (newline.not() & any()).star().flatten();

    // 内容: 次の "\n```" まで
    final content = any().starLazy(string('\n```')).flatten();

    // 開始部分を型安全にパース
    final startPart = seq4(lineBegin(), fence, langPart, newline);

    // 終了部分を型安全にパース
    final endPart = seq3(string('\n'), fence, lineEnd());

    return seq5(
      newline.optional(),
      startPart,
      content,
      endPart,
      newline.optional(),
    ).map((result) {
      final lang = result.$2.$3;
      final code = result.$3;
      return CodeBlockNode(
        code: code,
        language: lang.isEmpty ? null : lang,
      );
    });
  }
}
