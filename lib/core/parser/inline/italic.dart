import 'package:petitparser/petitparser.dart';
import '../../ast.dart';
import '../common/utils.dart';
import '../core/seq_or_text.dart';
import '../core/nest.dart';
import '../core/guards.dart';

/// 斜体構文パーサー
///
/// "*" または "_"、および "<i></i>" で囲まれた内容を解析する
class ItalicParser {
  /// 直前文字許可判定（英数字直後は不可、先頭/空白/改行/非英数字は可）
  bool _allowPrev(String? ch) {
    if (ch == null) return true;
    if (ch == ' ' || ch == '\n') return true;
    final code = ch.codeUnitAt(0);
    final bool isDigit = code >= 0x30 && code <= 0x39;
    final bool isUpper = code >= 0x41 && code <= 0x5A;
    final bool isLower = code >= 0x61 && code <= 0x7A;
    if (isDigit || isUpper || isLower) return false;
    return true;
  }

  /// 斜体ノードのパーサー（* ... *）
  Parser<MfmNode> build() {
    // 既存仕様: * は単体利用時フォールバックも提供するため、build() は buildWithFallback() と組にして利用
    final Parser<MfmNode> inner = any()
        .starLazy(string('*'))
        .flatten()
        .map<MfmNode>((dynamic v) => TextNode(v as String));

    final core = (string('*') & inner & string('*')).map<MfmNode>((dynamic v) {
      final List<dynamic> parts = v as List<dynamic>;
      final MfmNode content = parts[1] as MfmNode;
      return ItalicNode(mergeAdjacentTextNodes([content]));
    });

    return withPrevCharGuard(core, _allowPrev);
  }

  /// 斜体ノードのパーサー（* ... *）: 再帰合成版
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline) {
    final start = string('*');
    final end = string('*');
    final parser = seqOrText(start, nest(inline), end).map<MfmNode>((
      dynamic v,
    ) {
      if (v is String) {
        return TextNode(v);
      }
      final List<dynamic> seq = v as List<dynamic>;
      final List<MfmNode> children = (seq[1] as List).cast<MfmNode>();
      return ItalicNode(mergeAdjacentTextNodes(children));
    });
    return withPrevCharGuard(parser, _allowPrev);
  }

  /// 斜体タグ（<i> ... </i>）: 基本版
  Parser<MfmNode> buildTag() {
    final start = string('<i>');
    final end = string('</i>');
    final inner = (end.not() & any()).plus().flatten().map<MfmNode>(
      (dynamic v) => TextNode(v as String),
    );
    return (start & inner & end).map<MfmNode>((dynamic v) {
      final List<dynamic> parts = v as List<dynamic>;
      final MfmNode content = parts[1] as MfmNode;
      return ItalicNode(mergeAdjacentTextNodes([content]));
    });
  }

  /// 斜体タグ（<i> ... </i>）: 再帰合成版
  Parser<MfmNode> buildTagWithInner(Parser<MfmNode> inline) {
    final start = string('<i>');
    final end = string('</i>');
    final parser = seqOrText(start, nest(inline), end).map<MfmNode>((
      dynamic v,
    ) {
      if (v is String) return TextNode(v);
      final parts = v as List<dynamic>;
      final children = (parts[1] as List).cast<MfmNode>();
      return ItalicNode(mergeAdjacentTextNodes(children));
    });
    return parser;
  }

  /// 斜体ノードのパーサー（_ ... _）
  Parser<MfmNode> buildAlt2() {
    final Parser<MfmNode> inner = any()
        .starLazy(string('_'))
        .flatten()
        .map<MfmNode>((dynamic v) => TextNode(v as String));

    final core = (string('_') & inner & string('_')).map<MfmNode>((dynamic v) {
      final List<dynamic> parts = v as List<dynamic>;
      final MfmNode content = parts[1] as MfmNode;
      return ItalicNode(mergeAdjacentTextNodes([content]));
    });

    final complete = withPrevCharGuard(core, _allowPrev);

    final fallback = (string('_') & any().star()).flatten().map<MfmNode>(
      (dynamic s) => TextNode(s as String),
    );

    return (complete | fallback).cast<MfmNode>();
  }

  /// 斜体またはフォールバックのパーサー（* ... *）
  Parser<MfmNode> buildWithFallback() {
    final completeItalic = build();
    final fallback = (string('*') & any().star()).flatten().map<MfmNode>(
      (dynamic s) => TextNode(s as String),
    );
    return (completeItalic | fallback).cast<MfmNode>();
  }
}
