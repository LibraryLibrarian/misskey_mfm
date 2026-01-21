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
        .map<MfmNode>(TextNode.new);

    return seq3(mark, inner, mark).map((result) {
      final content = result.$2;
      return StrikeNode(mergeAdjacentTextNodes([content]));
    });
  }

  /// 打ち消し線ノードのパーサー（~~ ... ~~）: 再帰合成版
  ///
  /// 内容には `~~` と改行を含められない
  /// [state] ネスト状態（共有される）
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline, {NestState? state}) {
    final mark = string('~~');
    // `~~` と改行以外を許可
    final stopCondition = mark | char('\n');
    final inner = (stopCondition.not() & nest(inline, state: state))
        .pick(1)
        .cast<MfmNode>();
    final parser = seqOrText<MfmNode>(mark, inner, mark).map<MfmNode>((result) {
      return switch (result) {
        SeqOrTextFallback(:final text) => TextNode(text),
        SeqOrTextSuccess(:final children) => StrikeNode(
          mergeAdjacentTextNodes(children),
        ),
      };
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
      TextNode.new,
    );
    return seq3(start, inner, end).map((result) {
      return StrikeNode(mergeAdjacentTextNodes([result.$2]));
    });
  }

  /// 打ち消し線タグ（<s> ... </s>）: 再帰合成版
  ///
  /// 内容にはすべての文字、改行が使用可
  /// [state] ネスト状態（共有される）
  Parser<MfmNode> buildTagWithInner(
    Parser<MfmNode> inline, {
    NestState? state,
  }) {
    final start = string('<s>');
    final end = string('</s>');
    final parser = seqOrText<MfmNode>(start, nest(inline, state: state), end)
        .map<MfmNode>(
          (result) {
            return switch (result) {
              SeqOrTextFallback(:final text) => TextNode(text),
              SeqOrTextSuccess(:final children) => StrikeNode(
                mergeAdjacentTextNodes(children),
              ),
            };
          },
        );
    return parser;
  }

  /// 打ち消し線またはフォールバックのパーサー（~~ ... ~~）
  ///
  /// 打ち消し線として解析できない場合は、先頭"~~"以降の全文字列をテキストとして扱う
  Parser<MfmNode> buildWithFallback() {
    final completedStrike = build();

    final fallback = (string('~~') & any().star()).flatten().map<MfmNode>(
      TextNode.new,
    );

    return (completedStrike | fallback).cast<MfmNode>();
  }
}
