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
    final start = (fence & langPart & newline).map<String>(
      (dynamic v) => (v as List<dynamic>)[1] as String,
    );

    // 内容: 次の "\n```" まで
    final content = any().starLazy(string('\n```')).flatten();

    // 終了: \n``` （末尾の```のみを消費）
    final end = string('\n') & fence;

    return (start & content & end).map<MfmNode>((dynamic v) {
      final parts = v as List<dynamic>;
      final code = parts[1] as String; // 本文
      return CodeBlockNode(code: code);
    });
  }
}
