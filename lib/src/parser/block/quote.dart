import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../common/utils.dart';
import '../core/guards.dart';
import '../core/nest.dart';

/// 引用ブロックパーサー（単一/複数行対応）
///
/// 行頭の ">" と任意の空白1文字に続く行を1行以上引用として解析
///
/// 引用内容に対してフルパーサー（blocks + inline）を適用
/// quote内のquoteを含むすべての構文をパース
class QuoteParser {
  /// 引用（> ...）: 再帰パース対応版
  ///
  /// [fullParser] フルパーサー（blocks + inline、undefinedを使用）
  /// [state] ネスト状態（共有される）
  ///
  /// quoteの内部はfullParserでパースされ、ネストされたquoteも解析される
  /// "> " のみ（内容が空）の場合はパースに失敗し、TextNodeとして扱われる
  /// quoteの前後の改行（最大2つずつ）を消費する
  Parser<MfmNode> buildWithInner(
    Parser<MfmNode> fullParser, {
    NestState? state,
  }) {
    // `>` の後に続く0〜1文字の空白を無視
    final startMarker = seq2(
      char('>'),
      pattern(' \u3000\t').optional(),
    );
    final lineBreak = newline();

    // 1行のテキスト（改行直前まで）を文字列として取得
    final lineText = seq2(lineBreak.not(), any()).star().flatten();

    // 最初の行: ">" + 空白? + テキスト
    final firstLine = seq2(startMarker, lineText).map<String>(
      (result) => result.$2,
    );

    // 続く行: "\n" + ">" + 空白? + テキスト
    final nextLine = seq3(lineBreak, startMarker, lineText).map<String>(
      (result) => result.$3,
    );

    // 空行の個数を判定できるよう、引用行は配列のまま保持
    final allLines = seq2(firstLine, nextLine.star()).map<List<String>>(
      (result) => [result.$1, ...result.$2],
    );

    // 前後の改行を処理
    // 前の改行を最大2つ消費（optional）
    final newlineOpt = lineBreak.optional();

    // パーサー全体
    final parser = seq5(
      newlineOpt, // 前の改行1
      newlineOpt, // 前の改行2
      seq2(lineBegin(), allLines), // 行頭チェック + 引用行
      newlineOpt, // 後の改行1
      newlineOpt, // 後の改行2
    ).map((result) => result.$3.$2); // allLinesのみを取得

    // 引用内容をfullParserでパース（quoteを含むすべての構文）
    // 1行だけで内容が空の場合のみパースに失敗させる
    return parser
        .where((lines) => !(lines.length == 1 && lines[0].isEmpty))
        .map<MfmNode>((List<String> lines) {
          final content = lines.join('\n');

          // 引用内容に対してfullParserを適用（nest経由で深度管理）
          final innerParser = nest(fullParser, state: state).plus().end();
          final result = innerParser.parse(content);

          if (result is Success<List<MfmNode>>) {
            return QuoteNode(mergeAdjacentTextNodes(result.value));
          } else {
            // パース失敗時はテキストとして扱う
            return QuoteNode([TextNode(content)]);
          }
        });
  }
}
