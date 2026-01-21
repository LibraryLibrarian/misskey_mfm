import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../common/utils.dart';
import '../core/nest.dart';

/// 引用ブロックパーサー（単一/複数行対応）
///
/// 行頭の "> " または ">" に続く行を1行以上引用として解析
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
    // `>` の後に続く0〜1文字のスペースを無視
    final startMarker = string('> ') | string('>');
    final endLine = char('\n');

    // 1行のテキスト（改行直前まで）を文字列として取得
    final lineText = seq2(endLine.not(), any()).star().flatten();

    // 最初の行: "> " + テキスト
    final firstLine = seq2(startMarker, lineText).map<String>(
      (result) => result.$2,
    );

    // 続く行: "\n" + "> " + テキスト → "\n" + テキスト に変換
    final nextLine = seq3(endLine, startMarker, lineText).map<String>(
      (result) => '\n${result.$3}',
    );

    // 全引用行を結合して1つの文字列として取得
    final allLines = seq2(firstLine, nextLine.star()).map<String>((result) {
      final head = result.$1;
      final rest = result.$2.join();
      return head + rest;
    });

    // 前後の改行を処理
    // 前の改行を最大2つ消費（optional）
    final newlineOpt = char('\n').optional();

    // パーサー全体
    final parser = seq5(
      newlineOpt, // 前の改行1
      newlineOpt, // 前の改行2
      allLines,
      newlineOpt, // 後の改行1
      newlineOpt, // 後の改行2
    ).map((result) => result.$3); // allLinesのみを取得

    // 引用内容をfullParserでパース（quoteを含むすべての構文）
    // 内容が空白のみの場合はパースに失敗させる
    return parser.where((content) => content.trim().isNotEmpty).map<MfmNode>((
      String content,
    ) {
      if (content.isEmpty) {
        return const QuoteNode([]);
      }

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
