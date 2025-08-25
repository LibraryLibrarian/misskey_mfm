import 'package:petitparser/petitparser.dart';
import '../ast.dart';
import 'common/utils.dart';
import 'common/text.dart';
import 'inline/bold.dart';
import 'inline/italic.dart';

/// MFM（Misskey Flavored Markdown）メインパーサー
///
/// 各構文パーサーを統合し、適切な優先順位で解析を行う
class MfmParser {
  /// パーサーを構築して返す
  ///
  /// 戻り値: MFMテキストを解析するパーサー
  Parser<List<MfmNode>> build() {
    // expose start rule
    final Parser<List<MfmNode>> start = _inlines().end();
    return start;
  }

  /// インライン要素のパーサー
  ///
  /// 各インライン構文パーサーを統合し、適切な優先順位で解析する
  ///
  /// 戻り値: インライン要素のリストを解析するパーサー
  Parser<List<MfmNode>> _inlines() {
    // 太字パーサー（フォールバック付き）
    final boldParser = BoldParser().buildWithFallback();

    // 斜体パーサー（フォールバック付き）
    final italicParser = ItalicParser().buildWithFallback();

    // テキストパーサー（太字や斜体で始まらない任意の文字列）
    final textParser = TextParser.textNode('**').or(TextParser.textNode('*'));

    // 太字と斜体を優先し、それ以外はテキストとして処理
    return (boldParser | italicParser | textParser).plus().map(
      (List<dynamic> values) => mergeAdjacentTextNodes(values.cast<MfmNode>()),
    );
  }
}
