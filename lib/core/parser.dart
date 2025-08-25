import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'utils.dart';

/// MFM（Misskey Flavored Markdown）パーサー
///
/// 現在は基本的なインライン構文（テキストと太字）のみをサポートしている
/// 将来的には全てのMFM構文に対応予定
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
  /// 太字またはフォールバックテキストの連続を解析する
  ///
  /// 戻り値: インライン要素のリストを解析するパーサー
  Parser<List<MfmNode>> _inlines() => (_boldOrFallback() | _text()).plus().map(
    (List<dynamic> values) => mergeAdjacentTextNodes(values.cast<MfmNode>()),
  );

  /// テキストノードのパーサー
  ///
  /// "**"で始まらない任意の文字列を解析する
  ///
  /// 戻り値: テキストノードを解析するパーサー
  Parser<MfmNode> _text() {
    final Parser notBoldStartChar = (string('**').not() & any())
        .plus()
        .flatten();
    return notBoldStartChar.map<MfmNode>(
      (dynamic value) => TextNode(value as String),
    );
  }

  /// 太字ノードのパーサー
  ///
  /// "**"で囲まれた内容を解析し、ネストされた太字も処理する
  ///
  /// 戻り値: 太字ノードを解析するパーサー
  Parser<MfmNode> _bold() {
    late Parser<MfmNode> boldRef;
    final SettableParser<MfmNode> content = undefined();

    // 次の'**'の前までのテキストチャンク
    final Parser<MfmNode> textUntilBold =
        ((string('**').not() & any()).plus().flatten()).map<MfmNode>(
          (dynamic v) => TextNode(v as String),
        );

    // テキストを消費する前にネストされた太字を優先する
    boldRef = (string('**') & (content | textUntilBold).star() & string('**'))
        .map<MfmNode>((dynamic v) {
          final List<MfmNode> children = (v[1] as List).cast<MfmNode>();
          return BoldNode(mergeAdjacentTextNodes(children));
        });

    content.set(boldRef);

    return boldRef;
  }

  /// 太字またはフォールバックのパーサー
  ///
  /// 太字として解析できない場合は、単純なテキストとして扱う
  ///
  /// 戻り値: 太字またはテキストノードを解析するパーサー
  Parser<MfmNode> _boldOrFallback() {
    return (_bold() | string('**').map<MfmNode>((_) => const TextNode('**')))
        .cast<MfmNode>();
  }
}
