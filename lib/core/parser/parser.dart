import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'block/center.dart';
import 'block/code_block.dart';
import 'block/quote.dart';
import 'common/utils.dart';
import 'inline/bold.dart';
import 'inline/emoji_code.dart';
import 'inline/hashtag.dart';
import 'inline/inline_code.dart';
import 'inline/italic.dart';
import 'inline/link.dart';
import 'inline/mention.dart';
import 'inline/small.dart';
import 'inline/strike.dart';
import 'inline/unicode_emoji.dart';
import 'inline/url.dart';

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
    final strike = StrikeParser().buildWithInner(inline);
    final strikeTag = StrikeParser().buildTagWithInner(inline);
    final inlineCode = InlineCodeParser().buildWithFallback();

    // 絵文字パーサー
    final emojiCode = EmojiCodeParser().build();
    final unicodeEmoji = UnicodeEmojiParser().build();

    // メンション・ハッシュタグパーサー
    final mention = MentionParser().buildWithFallback();
    final hashtag = HashtagParser().buildWithFallback();

    // URL・リンクパーサー
    final url = UrlParser().buildWithFallback();
    final urlAlt = UrlParser().buildAlt();

    // リンクラベル用インラインパーサー（URL、リンク、メンションを除外）
    // mfm-js仕様: リンクラベル内ではURL、リンク、メンションは無効
    final labelInline = undefined<MfmNode>();
    final labelStopper =
        char('`') |
        char(':') | // emojiCode用
        char('#') | // hashtag用
        char(']') | // リンクラベル終端
        string('</small>') |
        string('<small>') |
        string('</s>') |
        string('<s>') |
        string('</b>') |
        string('<b>') |
        string('</i>') |
        string('<i>') |
        string('~~') |
        string('**') |
        string('*') |
        string('_');
    final labelTextParser = (labelStopper.not() & unicodeEmoji.not() & any())
        .plus()
        .flatten()
        .map<MfmNode>((dynamic v) => TextNode(v as String));
    final labelOneChar = any().map<MfmNode>(
      (dynamic c) => TextNode(c as String),
    );
    labelInline.set(
      (inlineCode |
              unicodeEmoji |
              emojiCode |
              hashtag | // メンションは除外、ハッシュタグは許可
              smallTag |
              strikeTag |
              boldTag |
              italicTag |
              strike |
              bold |
              italicAlt2 |
              italicAsterisk |
              labelTextParser |
              labelOneChar)
          .cast<MfmNode>(),
    );

    // リンクパーサー（ラベル用インラインパーサーを使用）
    final link = LinkParser().buildWithFallback(labelInline);

    final stopper =
        char('`') |
        char(':') | // emojiCode用
        char('@') | // mention用
        char('#') | // hashtag用
        char('[') | // link用
        string('?[') | // silent link用
        string('<https://') | // urlAlt用
        string('<http://') | // urlAlt用
        string('https://') | // url用
        string('http://') | // url用
        string('</center>') |
        string('<center>') |
        string('</small>') |
        string('<small>') |
        string('</s>') | // strike用
        string('<s>') | // strike用
        string('</b>') |
        string('<b>') |
        string('</i>') |
        string('<i>') |
        string('~~') | // strike用
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
              mention |
              hashtag |
              urlAlt | // <https://...> 形式（HTMLタグより前）
              smallTag |
              strikeTag |
              boldTag |
              italicTag |
              strike |
              bold |
              italicAlt2 |
              italicAsterisk |
              link | // [label](url) 形式
              url | // https://... 形式
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
