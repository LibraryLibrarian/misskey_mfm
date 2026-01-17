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
  /// [state] ネスト状態（共有される）
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline, {NestState? state}) {
    final start = string('<center>');
    final end = string('</center>');

    // 開始タグ直後の改行を削除
    final optionalNewlineAfterStart = char('\n').optional();

    // 終了タグ直前の改行を削除するため、
    // innerListの最後の要素がTextNodeで末尾が\nの場合は削除する
    final innerList = seq2(
      end.not(),
      nest(inline, state: state),
    ).map((r) => r.$2).plus();

    // 終了タグ直前の改行チェック
    final optionalNewlineBeforeEnd = char('\n').optional();

    final parser =
        seq5(
          start,
          optionalNewlineAfterStart,
          innerList,
          optionalNewlineBeforeEnd,
          end,
        ).map<MfmNode>((result) {
          final children = result.$3;
          // 最後のノードがTextNodeで末尾が\nの場合は削除
          final processed = _trimTrailingNewline(children);
          return CenterNode(mergeAdjacentTextNodes(processed));
        });
    return parser;
  }

  /// 最後のTextNodeの末尾の改行を削除
  List<MfmNode> _trimTrailingNewline(List<MfmNode> nodes) {
    if (nodes.isEmpty) return nodes;

    final last = nodes.last;
    if (last is TextNode && last.text.endsWith('\n')) {
      final trimmed = last.text.substring(0, last.text.length - 1);
      if (trimmed.isEmpty) {
        // 改行のみの場合は削除
        return nodes.sublist(0, nodes.length - 1);
      }
      return [
        ...nodes.sublist(0, nodes.length - 1),
        TextNode(trimmed),
      ];
    }
    return nodes;
  }
}
