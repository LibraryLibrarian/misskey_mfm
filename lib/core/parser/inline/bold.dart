import 'package:petitparser/petitparser.dart';
import '../../ast.dart';
import '../common/utils.dart';
import '../core/seq_or_text.dart';
import '../core/nest.dart';

/// 太字構文パーサー
///
/// "**" または "<b></b>" で囲まれた内容を解析する
class BoldParser {
  /// 太字ノードのパーサー（** ... **）
  Parser<MfmNode> build() {
    final Parser<MfmNode> inner = any()
        .starLazy(string('**'))
        .flatten()
        .map<MfmNode>((dynamic v) => TextNode(v as String));

    return (string('**') & inner & string('**')).map<MfmNode>((dynamic v) {
      final List<dynamic> parts = v as List<dynamic>;
      final MfmNode content = parts[1] as MfmNode;
      return BoldNode(mergeAdjacentTextNodes([content]));
    });
  }

  /// 太字ノードのパーサー（** ... **）: 再帰合成版
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline) {
    final start = string('**');
    final end = string('**');
    final parser = seqOrText(start, nest(inline), end).map<MfmNode>((
      dynamic v,
    ) {
      if (v is String) {
        return TextNode(v);
      }
      final List<dynamic> parts = v as List<dynamic>;
      final List<MfmNode> children = (parts[1] as List).cast<MfmNode>();
      return BoldNode(mergeAdjacentTextNodes(children));
    });
    return parser;
  }

  /// 太字タグ（<b> ... </b>）: 基本版
  Parser<MfmNode> buildTag() {
    final start = string('<b>');
    final end = string('</b>');
    final inner = (end.not() & any()).plus().flatten().map<MfmNode>(
      (dynamic v) => TextNode(v as String),
    );
    return (start & inner & end).map<MfmNode>((dynamic v) {
      final parts = v as List<dynamic>;
      return BoldNode(mergeAdjacentTextNodes([parts[1] as MfmNode]));
    });
  }

  /// 太字タグ（<b> ... </b>）: 再帰合成版
  Parser<MfmNode> buildTagWithInner(Parser<MfmNode> inline) {
    final start = string('<b>');
    final end = string('</b>');
    final parser = seqOrText(start, nest(inline), end).map<MfmNode>((
      dynamic v,
    ) {
      if (v is String) {
        return TextNode(v);
      }
      final List<dynamic> parts = v as List<dynamic>;
      final List<MfmNode> children = (parts[1] as List).cast<MfmNode>();
      return BoldNode(mergeAdjacentTextNodes(children));
    });
    return parser;
  }

  /// 太字またはフォールバックのパーサー（** ... **）
  ///
  /// 太字として解析できない場合は、先頭"**"以降の全文字列をテキストとして扱う
  Parser<MfmNode> buildWithFallback() {
    final completeBold = build();

    final fallback = (string('**') & any().star()).flatten().map<MfmNode>(
      (dynamic s) => TextNode(s as String),
    );

    return (completeBold | fallback).cast<MfmNode>();
  }
}
