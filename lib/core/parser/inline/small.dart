import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../common/utils.dart';
import '../core/nest.dart';
import '../core/seq_or_text.dart';

/// small 構文パーサー
///
/// "<small>…</small>" で囲まれた内容を解析する
class SmallParser {
  /// small タグ（基本版）
  Parser<MfmNode> build() {
    final start = string('<small>');
    final end = string('</small>');
    final inner = (end.not() & any()).plus().flatten().map<MfmNode>(
      TextNode.new,
    );
    return seq3(start, inner, end).map((result) {
      return SmallNode(mergeAdjacentTextNodes([result.$2]));
    });
  }

  /// small タグ（再帰合成版）
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline) {
    final start = string('<small>');
    final end = string('</small>');
    final parser = seqOrText<MfmNode>(start, nest(inline), end).map<MfmNode>((
      result,
    ) {
      return switch (result) {
        SeqOrTextFallback(:final text) => TextNode(text),
        SeqOrTextSuccess(:final children) => SmallNode(
          mergeAdjacentTextNodes(children),
        ),
      };
    });
    return parser;
  }
}
