import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../common/utils.dart';
import '../core/guards.dart';
import '../core/nest.dart';

/// 中央寄せブロックパーサー
///
/// "&lt;center&gt;…&lt;/center&gt;" で囲まれたブロックを解析
///
/// mfm-js仕様:
/// - `<center>` は行頭でなければならない（入力先頭または直前が改行）
/// - `</center>` は行末でなければならない（入力末尾または直後が改行）
/// - 前後の改行はブロック構文として消費される
class CenterParser {
  /// center タグ（基本版）
  Parser<MfmNode> build() {
    final lineBreak = newline();
    final start = string('<center>');
    final end = string('</center>');
    final inner = ((lineBreak.optional() & end).not() & any())
        .pick(1)
        .plus()
        .flatten()
        .map<MfmNode>(TextNode.new);

    // mfm-js仕様: 行頭/行末チェック、前後の改行消費
    return (lineBreak.optional() &
            lineBegin() &
            start &
            lineBreak.optional() &
            inner &
            lineBreak.optional() &
            end &
            lineEnd() &
            lineBreak.optional())
        .map<MfmNode>((result) {
          final content = result[4] as MfmNode;
          return CenterNode(mergeAdjacentTextNodes([content]));
        });
  }

  /// center タグ（再帰合成版）
  /// [state] ネスト状態（共有される）
  ///
  /// mfm-js仕様:
  /// - `<center>` は行頭でなければならない
  /// - `</center>` は行末でなければならない
  /// - 開始タグ前/終了タグ後の改行はブロック構文として消費される
  /// - 開始タグ直後/終了タグ直前の改行はトリミングされる
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline, {NestState? state}) {
    final lineBreak = newline();
    final start = string('<center>');
    final end = string('</center>');

    // 開始タグ直後の改行を削除
    final optionalNewlineAfterStart = lineBreak.optional();

    // 内容: 終了タグが出現するまでのインラインノード
    // mfm-js:
    //  P.seq(
    //    P.notMatch(
    //      P.seq(newLine.option(), close)
    //    ), nest(r.inline)
    //   ).select(1).many(1)
    final innerList = seq2(
      (lineBreak.optional() & end).not(),
      nest(inline, state: state),
    ).map((r) => r.$2).plus();

    // 終了タグ直前の改行チェック
    final optionalNewlineBeforeEnd = lineBreak.optional();

    // mfm-js仕様に基づくパーサー構造:
    // [改行?, 行頭, <center>, 改行?, 内容, 改行?, </center>, 行末, 改行?]
    final parser =
        (lineBreak.optional() &
                lineBegin() &
                start &
                optionalNewlineAfterStart &
                innerList &
                optionalNewlineBeforeEnd &
                end &
                lineEnd() &
                lineBreak.optional())
            .map<MfmNode>((result) {
              final children = result[4] as List<MfmNode>;
              return CenterNode(mergeAdjacentTextNodes(children));
            });
    return parser;
  }
}
