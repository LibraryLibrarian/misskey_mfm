import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../common/utils.dart';
import '../core/nest.dart';
import '../core/seq_or_text.dart';

/// 太字構文パーサー
///
/// "**" または "<b></b>" で囲まれた内容を解析する
class BoldParser {
  /// 太字ノードのパーサー（** ... **）
  Parser<MfmNode> build() {
    final inner = any()
        .starLazy(string('**'))
        .flatten()
        .map<MfmNode>(TextNode.new);

    return seq3(string('**'), inner, string('**')).map((result) {
      final content = result.$2;
      return BoldNode(mergeAdjacentTextNodes([content]));
    });
  }

  /// 太字ノードのパーサー（** ... **）: 再帰合成版
  /// [state] ネスト状態（共有される）
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline, {NestState? state}) {
    final start = string('**');
    final end = string('**');
    final parser = seqOrText<MfmNode>(start, nest(inline, state: state), end)
        .map<MfmNode>(
          (result) {
            return switch (result) {
              SeqOrTextFallback(:final text) => TextNode(text),
              SeqOrTextSuccess(:final children) => BoldNode(
                mergeAdjacentTextNodes(children),
              ),
            };
          },
        );
    return parser;
  }

  /// 太字タグ（<b> ... </b>）: 基本版
  Parser<MfmNode> buildTag() {
    final start = string('<b>');
    final end = string('</b>');
    final inner = (end.not() & any()).plus().flatten().map<MfmNode>(
      TextNode.new,
    );
    return seq3(start, inner, end).map((result) {
      return BoldNode(mergeAdjacentTextNodes([result.$2]));
    });
  }

  /// 太字タグ（<b> ... </b>）: 再帰合成版
  /// [state] ネスト状態（共有される）
  Parser<MfmNode> buildTagWithInner(
    Parser<MfmNode> inline, {
    NestState? state,
  }) {
    final start = string('<b>');
    final end = string('</b>');
    final parser = seqOrText<MfmNode>(start, nest(inline, state: state), end)
        .map<MfmNode>(
          (result) {
            return switch (result) {
              SeqOrTextFallback(:final text) => TextNode(text),
              SeqOrTextSuccess(:final children) => BoldNode(
                mergeAdjacentTextNodes(children),
              ),
            };
          },
        );
    return parser;
  }

  /// 太字またはフォールバックのパーサー（** ... **）
  ///
  /// 太字として解析できない場合は、先頭"**"以降の全文字列をテキストとして扱う
  Parser<MfmNode> buildWithFallback() {
    final completeBold = build();

    final fallback = (string('**') & any().star()).flatten().map<MfmNode>(
      TextNode.new,
    );

    return (completeBold | fallback).cast<MfmNode>();
  }

  /// 太字アンダースコア構文パーサー（__ ... __）
  ///
  /// mfm-js仕様:
  /// - `__` で囲まれた内容を太字として解析
  /// - 内容は `[a-z0-9 \t]` のみ許可（英数字、半角スペース、全角スペース、タブ）
  /// - 再帰パースなし（内部のインライン構文は解釈されない）
  ///
  /// 注意: ** や <b> とは異なり、再帰的なパースは行わない
  Parser<MfmNode> buildUnder() {
    final mark = string('__');
    // 英数字、半角スペース、全角スペース(\u3000)、タブのみ許可
    // mfm-js: P.alt([alphaAndNum, space]) where space = /[\u0020\u3000\t]/
    // パターンを統合することでSingleCharacterParserとして最適化可能
    final inner = pattern('a-zA-Z0-9\u0020\u3000\t').plusString();

    return seq3(mark, inner, mark).map((result) {
      final text = result.$2;
      return BoldNode(mergeAdjacentTextNodes([TextNode(text)]));
    });
  }
}
