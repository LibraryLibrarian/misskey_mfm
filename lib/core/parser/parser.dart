import 'package:petitparser/petitparser.dart';
import '../ast.dart';
import 'common/utils.dart';
import 'inline/bold.dart';
import 'inline/italic.dart';
import 'core/nest.dart';

/// MFM（Misskey Flavored Markdown）メインパーサー
///
/// 各構文パーサーを統合し、適切な優先順位で解析を行う
class MfmParser {
  /// コンストラクタ
  ///
  /// [nestLimit]ネスト上限（nullなら無制限）。既定は20
  MfmParser({int? nestLimit}) : _nestState = NestState(limit: nestLimit ?? 20);

  final NestState _nestState;

  /// パーサーを構築して返す
  ///
  /// 戻り値: MFMテキストを解析するパーサー
  Parser<List<MfmNode>> build() {
    final SettableParser<MfmNode> inline = undefined();

    // 再帰で利用されるinlineを、nest経由で制限を効かせつつ渡す
    final bold = BoldParser().buildWithInner(nest(inline, state: _nestState));
    final boldTag = BoldParser().buildTagWithInner(
      nest(inline, state: _nestState),
    );
    final italicAsterisk = ItalicParser().buildWithInner(
      nest(inline, state: _nestState),
    );
    final italicTag = ItalicParser().buildTagWithInner(
      nest(inline, state: _nestState),
    );
    final italicAlt2 = ItalicParser().buildAlt2();

    final stopper =
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
      (boldTag |
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
