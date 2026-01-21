import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../common/utils.dart';
import '../core/guards.dart';
import '../core/nest.dart';
import '../core/seq_or_text.dart';

/// 斜体構文パーサー
///
/// "*" または "_"、および "<i></i>" で囲まれた内容を解析する
class ItalicParser {
  /// 直前文字許可判定（英数字直後は不可、先頭/空白/改行/非英数字は可）
  bool _allowPrev(String? ch) {
    if (ch == null) return true;
    if (ch == ' ' || ch == '\n') return true;
    final code = ch.codeUnitAt(0);
    final isDigit = code >= 0x30 && code <= 0x39;
    final isUpper = code >= 0x41 && code <= 0x5A;
    final isLower = code >= 0x61 && code <= 0x7A;
    if (isDigit || isUpper || isLower) return false;
    return true;
  }

  /// 斜体ノードのパーサー（* ... *）
  Parser<MfmNode> build() {
    // 既存仕様: * は単体利用時フォールバックも提供するため、build() は buildWithFallback() と組にして利用
    final inner = any()
        .starLazy(string('*'))
        .flatten()
        .map<MfmNode>(TextNode.new);

    final core = seq3(string('*'), inner, string('*')).map((result) {
      final content = result.$2;
      return ItalicNode(mergeAdjacentTextNodes([content]));
    });

    return withPrevCharGuard(core, _allowPrev);
  }

  /// 斜体ノードのパーサー（* ... *）: 再帰合成版
  /// [state] ネスト状態（共有される）
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline, {NestState? state}) {
    final start = string('*');
    final end = string('*');
    final parser = seqOrText<MfmNode>(start, nest(inline, state: state), end)
        .map<MfmNode>(
          (result) {
            return switch (result) {
              SeqOrTextFallback(:final text) => TextNode(text),
              SeqOrTextSuccess(:final children) => ItalicNode(
                mergeAdjacentTextNodes(children),
              ),
            };
          },
        );
    return withPrevCharGuard(parser, _allowPrev);
  }

  /// 斜体タグ（<i> ... </i>）: 基本版
  Parser<MfmNode> buildTag() {
    final start = string('<i>');
    final end = string('</i>');
    final inner = (end.not() & any()).plus().flatten().map<MfmNode>(
      TextNode.new,
    );
    return seq3(start, inner, end).map((result) {
      final content = result.$2;
      return ItalicNode(mergeAdjacentTextNodes([content]));
    });
  }

  /// 斜体タグ（<i> ... </i>）: 再帰合成版
  /// [state] ネスト状態（共有される）
  Parser<MfmNode> buildTagWithInner(
    Parser<MfmNode> inline, {
    NestState? state,
  }) {
    final start = string('<i>');
    final end = string('</i>');
    final parser = seqOrText<MfmNode>(start, nest(inline, state: state), end)
        .map<MfmNode>(
          (result) {
            return switch (result) {
              SeqOrTextFallback(:final text) => TextNode(text),
              SeqOrTextSuccess(:final children) => ItalicNode(
                mergeAdjacentTextNodes(children),
              ),
            };
          },
        );
    return parser;
  }

  /// 斜体ノードのパーサー（_ ... _）
  Parser<MfmNode> buildAlt2() {
    final inner = any()
        .starLazy(string('_'))
        .flatten()
        .map<MfmNode>(TextNode.new);

    final core = seq3(string('_'), inner, string('_')).map((result) {
      final content = result.$2;
      return ItalicNode(mergeAdjacentTextNodes([content]));
    });

    final complete = withPrevCharGuard(core, _allowPrev);

    final fallback = (string('_') & any().star()).flatten().map<MfmNode>(
      TextNode.new,
    );

    return (complete | fallback).cast<MfmNode>();
  }

  /// 斜体またはフォールバックのパーサー（* ... *）
  Parser<MfmNode> buildWithFallback() {
    final completeItalic = build();
    final fallback = (string('*') & any().star()).flatten().map<MfmNode>(
      TextNode.new,
    );
    return (completeItalic | fallback).cast<MfmNode>();
  }
}
