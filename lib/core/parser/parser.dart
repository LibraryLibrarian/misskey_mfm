import 'package:petitparser/petitparser.dart';
import '../ast.dart';
import 'common/utils.dart';
import 'inline/bold.dart';
import 'inline/italic.dart';
import 'inline/small.dart';
import 'block/quote.dart';

/// MFM（Misskey Flavored Markdown）メインパーサー
///
/// 各構文パーサーを統合し、適切な優先順位で解析を行う
class MfmParser {
  /// パーサーを構築して返す
  Parser<List<MfmNode>> build() {
    final SettableParser<MfmNode> inline = undefined();

    final bold = BoldParser().buildWithInner(inline);
    final boldTag = BoldParser().buildTagWithInner(inline);
    final italicAsterisk = ItalicParser().buildWithInner(inline);
    final italicTag = ItalicParser().buildTagWithInner(inline);
    final italicAlt2 = ItalicParser().buildAlt2();
    final smallTag = SmallParser().buildWithInner(inline);

    final stopper =
        string('</small>') |
        string('<small>') |
        string('</b>') |
        string('<b>') |
        string('</i>') |
        string('<i>') |
        string('**') |
        string('*') |
        string('_');
    final textParser = (stopper.not() & any()).plus().flatten().map<MfmNode>(
      (dynamic v) => TextNode(v as String),
    );
    final oneChar = any().map<MfmNode>((dynamic c) => TextNode(c as String));
    inline.set(
      (smallTag |
              boldTag |
              italicTag |
              bold |
              italicAlt2 |
              italicAsterisk |
              textParser |
              oneChar)
          .cast<MfmNode>(),
    );

    // blocks（現状: 引用のみ、複数行対応の簡易版）
    final quote = QuoteParser().build();
    final blocks = quote;

    // 全体構成: ブロックで始まればブロック、そうでなければインラインの列
    final start = (blocks | inline)
        .plus()
        .map(
          (List<dynamic> values) =>
              mergeAdjacentTextNodes(values.cast<MfmNode>()),
        )
        .end();

    return start;
  }
}
