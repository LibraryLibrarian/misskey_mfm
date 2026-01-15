import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'block/center.dart';
import 'block/code_block.dart';
import 'block/quote.dart';
import 'common/utils.dart';
import 'inline/bold.dart';
import 'inline/emoji_code.dart';
import 'inline/inline_code.dart';
import 'inline/italic.dart';
import 'inline/small.dart';
import 'inline/unicode_emoji.dart';

/// MFM（Misskey Flavored Markdown）メインパーサー
///
/// 各構文パーサーを統合し、適切な優先順位で解析を行う
class MfmParser {
  /// パーサーを構築して返す
  Parser<List<MfmNode>> build() {
    final inline = undefined<MfmNode>();

    final bold = BoldParser().buildWithInner(inline);
    final boldTag = BoldParser().buildTagWithInner(inline);
    final italicAsterisk = ItalicParser().buildWithInner(inline);
    final italicTag = ItalicParser().buildTagWithInner(inline);
    final italicAlt2 = ItalicParser().buildAlt2();
    final smallTag = SmallParser().buildWithInner(inline);
    final inlineCode = InlineCodeParser().buildWithFallback();

    // 絵文字パーサー
    final emojiCode = EmojiCodeParser().build();
    final unicodeEmoji = UnicodeEmojiParser().build();

    final stopper =
        char('`') |
        char(':') | // emojiCode用
        string('</center>') |
        string('<center>') |
        string('</small>') |
        string('<small>') |
        string('</b>') |
        string('<b>') |
        string('</i>') |
        string('<i>') |
        string('**') |
        string('*') |
        string('_');
    final textParser = (stopper.not() & unicodeEmoji.not() & any())
        .plus()
        .flatten()
        .map<MfmNode>((dynamic v) => TextNode(v as String));
    final oneChar = any().map<MfmNode>((dynamic c) => TextNode(c as String));
    inline.set(
      (inlineCode |
              unicodeEmoji |
              emojiCode |
              smallTag |
              boldTag |
              italicTag |
              bold |
              italicAlt2 |
              italicAsterisk |
              textParser |
              oneChar)
          .cast<MfmNode>(),
    );

    // blocks: code block > center > quote
    final codeBlock = CodeBlockParser().build();
    final center = CenterParser().buildWithInner(inline);
    final quote = QuoteParser().buildWithInner(inline);
    final blocks = codeBlock | center | quote;

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
