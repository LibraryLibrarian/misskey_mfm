import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../common/utils.dart';
import '../core/nest.dart';
import '../core/seq_or_text.dart';

/// 打ち消し線構文パーサー
///
/// "~~" または "<s></s>" で囲まれた内容を解析する
class StrikeParser {
  /// 打ち消し線ノードのパーサー（~~ ... ~~）: 基本版
  ///
  /// 内容には `~` と改行を含められない
  Parser<MfmNode> build() {
    final mark = string('~~');
    // `~` と改行以外の文字のみ許可
    final inner = (mark.not() & char('~').not() & char('\n').not() & any())
        .pick(3)
        .plus()
        .flatten()
        .map<MfmNode>((dynamic v) => TextNode(v as String));

    return (mark & inner & mark).map<MfmNode>((dynamic v) {
      final parts = v as List<dynamic>;
      final content = parts[1] as MfmNode;
      return StrikeNode(mergeAdjacentTextNodes([content]));
    });
  }

  /// 打ち消し線ノードのパーサー（~~ ... ~~）: 再帰合成版
  ///
  /// 内容には `~~` と改行を含められない
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline) {
    final mark = string('~~');
    // `~~` と改行以外を許可
    final stopCondition = mark | char('\n');
    final parser =
        seqOrText(
          mark,
          (stopCondition.not() & nest(inline)).pick(1),
          mark,
        ).map<MfmNode>((dynamic v) {
          if (v is String) return TextNode(v);
          final parts = v as List<dynamic>;
          final children = (parts[1] as List).cast<MfmNode>();
          return StrikeNode(mergeAdjacentTextNodes(children));
        });
    return parser;
  }

  /// 打ち消し線タグ（<s> ... </s>）: 基本版
  ///
  /// 内容にはすべての文字、改行が使用可
  Parser<MfmNode> buildTag() {
    final start = string('<s>');
    final end = string('</s>');
    final inner = (end.not() & any()).plus().flatten().map<MfmNode>(
      (dynamic v) => TextNode(v as String),
    );
    return (start & inner & end).map<MfmNode>((dynamic v) {
      final parts = v as List<dynamic>;
      return StrikeNode(mergeAdjacentTextNodes([parts[1] as MfmNode]));
    });
  }

  /// 打ち消し線タグ（<s> ... </s>）: 再帰合成版
  ///
  /// 内容にはすべての文字、改行が使用可
  Parser<MfmNode> buildTagWithInner(Parser<MfmNode> inline) {
    final start = string('<s>');
    final end = string('</s>');
    final parser = seqOrText(start, nest(inline), end).map<MfmNode>((
      dynamic v,
    ) {
      if (v is String) return TextNode(v);
      final parts = v as List<dynamic>;
      final children = (parts[1] as List).cast<MfmNode>();
      return StrikeNode(mergeAdjacentTextNodes(children));
    });
    return parser;
  }

  /// 打ち消し線またはフォールバックのパーサー（~~ ... ~~）
  ///
  /// 打ち消し線として解析できない場合は、先頭"~~"以降の全文字列をテキストとして扱う
  Parser<MfmNode> buildWithFallback() {
    final completedStrike = build();

    final fallback = (string('~~') & any().star()).flatten().map<MfmNode>(
      (dynamic s) => TextNode(s as String),
    );

    return (completedStrike | fallback).cast<MfmNode>();
  }
}
