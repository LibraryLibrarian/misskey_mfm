import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../common/utils.dart';
import '../core/nest.dart';
import '../core/seq_or_text.dart';

/// big構文パーサー
///
/// "***" で囲まれた内容を `$[tada ...]` (FnNode) として解析
///
/// mfm-js仕様:
/// - `***...***` を `FnNode(name: 'tada', args: {}, children: [...])` として解析
/// - 内容にはインライン構文を利用可能（再帰パース）
/// - 改行も許可
///
/// 注意: この構文は廃止予定で、新規のコンテンツでは `$[tada ...]` の使用を推奨
class BigParser {
  /// big構文パーサー（*** ... ***）: 基本版
  ///
  /// 内容はTextNodeとしてのみ解析
  Parser<MfmNode> build() {
    final mark = string('***');
    final inner = any().starLazy(mark).flatten().map<MfmNode>(TextNode.new);

    return seq3(mark, inner, mark).map((result) {
      final content = result.$2;
      return FnNode(
        name: 'tada',
        args: <String, dynamic>{},
        children: mergeAdjacentTextNodes([content]),
      );
    });
  }

  /// big構文パーサー（*** ... ***）: 再帰合成版
  ///
  /// 内容にはインライン構文を利用可能
  /// [state] ネスト状態（共有される）
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline, {NestState? state}) {
    final mark = string('***');
    final parser = seqOrText<MfmNode>(mark, nest(inline, state: state), mark)
        .map<MfmNode>((
          result,
        ) {
          return switch (result) {
            SeqOrTextFallback(:final text) => TextNode(text),
            SeqOrTextSuccess(:final children) => FnNode(
              name: 'tada',
              args: <String, dynamic>{},
              children: mergeAdjacentTextNodes(children),
            ),
          };
        });
    return parser;
  }

  /// bigまたはフォールバックのパーサー（*** ... ***）
  ///
  /// big構文として解析できない場合は、先頭"***"以降の全文字列をテキストとして扱う
  Parser<MfmNode> buildWithFallback() {
    final completeBig = build();

    final fallback = (string('***') & any().star()).flatten().map<MfmNode>(
      TextNode.new,
    );

    return (completeBig | fallback).cast<MfmNode>();
  }
}
