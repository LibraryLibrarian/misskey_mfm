import 'package:petitparser/petitparser.dart';
import '../../ast.dart';
import '../common/utils.dart';
import '../core/seq_or_text.dart';
import '../core/nest.dart';

/// 中央寄せブロックパーサー
///
/// "&lt;center&gt;…&lt;/center&gt;" で囲まれたブロックを解析する
class CenterParser {
  /// center タグ（基本版）
  Parser<MfmNode> build() {
    final start = string('<center>');
    final end = string('</center>');
    final inner = (end.not() & any()).plus().flatten().map<MfmNode>(
      (dynamic v) => TextNode(v as String),
    );
    return (start & inner & end).map<MfmNode>((dynamic v) {
      final parts = v as List<dynamic>;
      return CenterNode(mergeAdjacentTextNodes([parts[1] as MfmNode]));
    });
  }

  /// center タグ（再帰合成版）
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline) {
    final start = string('<center>');
    final end = string('</center>');
    final parser = seqOrText(start, nest(inline), end).map<MfmNode>((
      dynamic v,
    ) {
      if (v is String) return TextNode(v);
      final parts = v as List<dynamic>;
      final children = (parts[1] as List).cast<MfmNode>();
      return CenterNode(mergeAdjacentTextNodes(children));
    });
    return parser;
  }
}
