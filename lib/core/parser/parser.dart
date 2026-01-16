import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'block/center.dart';
import 'block/code_block.dart';
import 'block/math_block.dart';
import 'block/quote.dart';
import 'block/search.dart';
import 'common/utils.dart';
import 'inline/bold.dart';
import 'inline/emoji_code.dart';
import 'inline/fn.dart';
import 'inline/hashtag.dart';
import 'inline/inline_code.dart';
import 'inline/italic.dart';
import 'inline/link.dart';
import 'inline/math_inline.dart';
import 'inline/mention.dart';
import 'inline/plain.dart';
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

    // plainタグパーサー（パース無効化）
    final plainTag = PlainParser().build();

    // インライン数式パーサー
    final mathInline = MathInlineParser().build();

    // 絵文字パーサー
    final emojiCode = EmojiCodeParser().build();
    final unicodeEmoji = UnicodeEmojiParser().build();

    // メンション・ハッシュタグパーサー
    final mention = MentionParser().buildWithFallback();
    final hashtag = HashtagParser().buildWithFallback();

    // URL・リンクパーサー
    final url = UrlParser().buildWithFallback();
    final urlAlt = UrlParser().buildAlt();

    // MFM関数パーサー
    final fn = FnParser().buildWithInner(inline);

    // リンクラベル用インラインパーサー（URL、リンク、メンションを除外）
    // mfm-js仕様: リンクラベル内ではURL、リンク、メンションは無効
    final labelInline = undefined<MfmNode>();
    final labelStopper =
        char('`') |
        char(':') | // emojiCode用
        char('#') | // hashtag用
        char(']') | // リンクラベル終端
        string(r'$[') | // fn用
        string('</plain>') | // plain用
        string('<plain>') | // plain用
        string('</small>') |
        string('<small>') |
        string('</s>') |
        string('<s>') |
        string('</b>') |
        string('<b>') |
        string('</i>') |
        string('<i>') |
        string(r'\(') | // mathInline用
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
    // ラベル内用fnパーサー（labelInlineを使用）
    final labelFn = FnParser().buildWithInner(labelInline);

    labelInline.set(
      (inlineCode |
              unicodeEmoji |
              emojiCode |
              hashtag | // メンションは除外、ハッシュタグは許可
              labelFn | // fn はリンクラベル内でも有効
              plainTag | // <plain>...</plain> 形式
              smallTag |
              strikeTag |
              boldTag |
              italicTag |
              strike |
              bold |
              italicAlt2 |
              italicAsterisk |
              mathInline | // \(...\) 形式
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
        char(']') | // fn終端用
        string('?[') | // silent link用
        string(r'$[') | // fn用
        string('<https://') | // urlAlt用
        string('<http://') | // urlAlt用
        string('https://') | // url用
        string('http://') | // url用
        string('</center>') |
        string('<center>') |
        string('</plain>') | // plain用
        string('<plain>') | // plain用
        string('</small>') |
        string('<small>') |
        string('</s>') | // strike用
        string('<s>') | // strike用
        string('</b>') |
        string('<b>') |
        string('</i>') |
        string('<i>') |
        string(r'\(') | // mathInline用
        string(r'\[') | // mathBlock用
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
              fn | // $[name content] 形式
              urlAlt | // <https://...> 形式（HTMLタグより前）
              plainTag | // <plain>...</plain> 形式
              smallTag |
              strikeTag |
              boldTag |
              italicTag |
              strike |
              bold |
              italicAlt2 |
              italicAsterisk |
              mathInline | // \(...\) 形式
              link | // [label](url) 形式
              url | // https://... 形式
              textParser |
              oneChar)
          .cast<MfmNode>(),
    );

    // blocks: code block > math block > center > quote > search
    final codeBlock = CodeBlockParser().build();
    final mathBlock = MathBlockParser().build();
    final center = CenterParser().buildWithInner(inline);
    final quote = QuoteParser().buildWithInner(inline);
    final search = SearchParser().build();
    final blocks = codeBlock | mathBlock | center | quote | search;

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
