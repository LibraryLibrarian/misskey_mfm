import 'package:petitparser/petitparser.dart';
import '../../ast.dart';
import '../common/utils.dart';

/// 引用ブロックパーサー（単一/複数行の基本対応）
///
/// 行頭の "> " に続く行を1行以上引用として解析する。
/// 各行の内容はプレーンテキストとして収集し、行の区切りは改行として `TextNode("\n")` を挟んで連結する。
class QuoteParser {
  /// 引用（> ...）: 複数行（簡易版: テキストのみ）
  Parser<MfmNode> build() {
    final startMarker = string('> ');
    final endLine = char('\n');

    // 1行のテキスト（改行直前まで）
    final lineText = (endLine.not() & any()).star().flatten().map<MfmNode>(
      (dynamic v) => TextNode(v as String),
    );

    final firstLine = (startMarker & lineText).map<List<MfmNode>>(
      (dynamic v) => [(v as List<dynamic>)[1] as MfmNode],
    );

    final nextLine = (endLine & startMarker & lineText).map<List<MfmNode>>(
      (dynamic v) => [const TextNode('\n'), (v as List<dynamic>)[2] as MfmNode],
    );

    final parser = (firstLine & nextLine.star()).map<MfmNode>((dynamic v) {
      final parts = v as List<dynamic>;
      final head = parts[0] as List<MfmNode>;
      final rest = (parts[1] as List)
          .expand<MfmNode>((dynamic e) => e as List<MfmNode>)
          .toList();
      final all = <MfmNode>[...head, ...rest];
      return QuoteNode(mergeAdjacentTextNodes(all));
    });

    return parser;
  }
}
