import 'package:petitparser/petitparser.dart';
import '../ast.dart';
import 'common/utils.dart';
import 'inline/bold.dart';
import 'inline/italic.dart';
import 'inline/small.dart';

/// MFM（Misskey Flavored Markdown）メインパーサー
///
/// 各構文パーサーを統合し、適切な優先順位で解析を行う
class MfmParser {
  /// パーサーを構築して返す
  ///
  /// 戻り値: MFMテキストを解析するパーサー
  Parser<List<MfmNode>> build() {
    // 再帰的 inline 合成
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

    final Parser<List<MfmNode>> start = inline
        .plus()
        .map(
          (List<dynamic> values) =>
              mergeAdjacentTextNodes(values.cast<MfmNode>()),
        )
        .end();
    return start;
  }
}
