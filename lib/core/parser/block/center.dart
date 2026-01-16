import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../common/utils.dart';
import '../core/nest.dart';

/// 中央寄せブロックパーサー
///
/// "&lt;center&gt;…&lt;/center&gt;" で囲まれたブロックを解析
class CenterParser {
  /// center タグ（基本版）
  Parser<MfmNode> build() {
    final start = string('<center>');
    final end = string('</center>');
    final inner = (end.not() & any()).plus().flatten().map<MfmNode>(
      TextNode.new,
    );
    return seq3(start, inner, end).map((result) {
      return CenterNode(mergeAdjacentTextNodes([result.$2]));
    });
  }

  /// center タグ（再帰合成版）
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline) {
    final start = string('<center>');
    final end = string('</center>');
    final innerList = seq2(end.not(), nest(inline)).map((r) => r.$2).plus();
    final parser = seq3(start, innerList, end).map<MfmNode>((result) {
      return CenterNode(mergeAdjacentTextNodes(result.$2));
    });
    return parser;
  }
}
