import 'package:petitparser/petitparser.dart';
import '../../ast.dart';
import '../common/utils.dart';
import '../core/seq_or_text.dart';
import '../core/nest.dart';

/// small 構文パーサー
///
/// "<small>…</small>" で囲まれた内容を解析する
class SmallParser {
  /// small タグ（基本版）
  Parser<MfmNode> build() {
    final start = string('<small>');
    final end = string('</small>');
    final inner = (end.not() & any()).plus().flatten().map<MfmNode>(
      (dynamic v) => TextNode(v as String),
    );
    return (start & inner & end).map<MfmNode>((dynamic v) {
      final parts = v as List<dynamic>;
      return SmallNode(mergeAdjacentTextNodes([parts[1] as MfmNode]));
    });
  }

  /// small タグ（再帰合成版）
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline) {
    final start = string('<small>');
    final end = string('</small>');
    final parser = seqOrText(start, nest(inline), end).map<MfmNode>((
      dynamic v,
    ) {
      if (v is String) return TextNode(v);
      final parts = v as List<dynamic>;
      final children = (parts[1] as List).cast<MfmNode>();
      return SmallNode(mergeAdjacentTextNodes(children));
    });
    return parser;
  }
}
