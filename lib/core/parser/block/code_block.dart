import 'package:petitparser/petitparser.dart';
import '../../ast.dart';

/// コードブロックパーサー
///
/// 三連バッククォートで囲まれたコードブロックを解析する。
/// 形式:
/// ```
/// ```[lang]\n
/// &lt;content...&gt;\n
/// ```
/// ```
/// - [lang] は無視（ハイライト等は行わないため破棄）
/// - 終了フェンスは行頭の "```" である必要がある
/// - 内容中の "```" は無視（終了フェンス直前の改行+"```" のみが終わり）
class CodeBlockParser {
  /// コードブロックの基本パーサー
  Parser<MfmNode> build() {
    final fence = string('```');
    final newline = char('\n');

    // 言語指定 (改行まで) - 破棄対象
    final langPart = (newline.not() & any()).star().flatten();

    // 開始: ``` + lang + \n → 言語文字列にマップするが後段で破棄
    final start = (fence & langPart & newline).map<String>(
      (dynamic v) => ((v as List<dynamic>)[1] as String),
    );

    // 内容: 次の "\n```" まで
    final content = any().starLazy(string('\n```')).flatten();

    // 終了: \n``` （末尾の```のみを消費）
    final end = string('\n') & fence;

    return (start & content & end).map<MfmNode>((dynamic v) {
      final parts = v as List<dynamic>;
      final String code = parts[1] as String; // 本文
      return CodeBlockNode(code: code, language: null);
    });
  }
}
