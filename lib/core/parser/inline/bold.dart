import 'package:petitparser/petitparser.dart';
import '../../ast.dart';
import '../common/utils.dart';
import '../core/seq_or_text.dart';
import '../core/nest.dart';

/// 太字構文パーサー
///
/// "**"で囲まれた内容を解析し、最近接の閉じタグまでを対象とする
class BoldParser {
  /// 太字ノードのパーサーを構築する
  ///
  /// 戻り値: 太字ノードを解析するパーサー
  Parser<MfmNode> build() {
    // 最近接の"**"までを内容として取得
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

  /// 太字ノードのパーサー（seqOrText + nest 版）
  ///
  /// mfm.js の `seqOrText`/`nest` を参考にした合成
  /// 現状は `nest` が簡易版のため、`inner` は `nest(inline)` ではなくテキストベース
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline) {
    final start = string('**');
    final end = string('**');
    final innerSeq = (end.not() & nest(inline))
        .map((dynamic v) => (v as List)[1])
        .plus();
    final parser = seqOrText(start, innerSeq, end).map<MfmNode>((dynamic v) {
      if (v is String) {
        return TextNode(v);
      }
      final List<dynamic> seq = v as List<dynamic>;
      final List<MfmNode> children = (seq[1] as List).cast<MfmNode>();
      return BoldNode(mergeAdjacentTextNodes(children));
    });
    return parser;
  }

  /// 太字またはフォールバックのパーサー
  ///
  /// 太字として解析できない場合は、先頭"**"以降の全文字列をテキストとして扱う
  ///
  /// 戻り値: 太字またはテキストノードを解析するパーサー
  Parser<MfmNode> buildWithFallback() {
    final completeBold = build();

    // フォールバック: '**'以降の全文字列をそのまま返す
    final fallback = (string('**') & any().star()).flatten().map<MfmNode>(
      (dynamic s) => TextNode(s as String),
    );

    return (completeBold | fallback).cast<MfmNode>();
  }
}
