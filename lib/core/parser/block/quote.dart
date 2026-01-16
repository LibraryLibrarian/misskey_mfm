import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../common/utils.dart';
import '../core/nest.dart';

/// 引用ブロックパーサー（単一/複数行対応）
///
/// 行頭の "> " または ">" に続く行を1行以上引用として解析
///
/// 引用内容に対してインラインパーサーを適用
/// bold、italic、emojiCode等のインライン構文をパース
class QuoteParser {
  /// 引用（> ...）: 再帰パース対応版
  ///
  /// [inline] インラインパーサー（bold, italic等を含む）
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline) {
    // mfm-js仕様: `>` の後に続く0〜1文字のスペースを無視
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

    // 引用内容をインラインパーサーでパース
    return allLines.map<MfmNode>((String content) {
      if (content.isEmpty) {
        return const QuoteNode([]);
      }

      // 引用内容に対してインラインパーサーを適用
      final innerParser = nest(inline).plus().end();
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
