import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'block/center.dart';
import 'block/code_block.dart';
import 'block/math_block.dart';
import 'block/quote.dart';
import 'block/search.dart';
import 'common/utils.dart';
import 'inline/big.dart';
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

    // big構文（廃止予定だが後方互換性のため実装）
    // *** は ** より先にチェックする必要がある
    final big = BigParser().buildWithInner(inline);
    final bold = BoldParser().buildWithInner(inline);
    final boldTag = BoldParser().buildTagWithInner(inline);
    // __ は _ より先にチェックする必要がある
    final boldUnder = BoldParser().buildUnder();
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
        string('***') | // big用（**より先にチェック）
        string('**') |
        string('__') | // boldUnder用（_より先にチェック）
        string('*') |
        string('_');
    final labelTextParser = (labelStopper.not() & unicodeEmoji.not() & any())
        .plus()
        .flatten()
        .map(TextNode.new);
    final labelOneChar = any().map(TextNode.new);
    // ラベル内用fnパーサー（labelInlineを使用）
    final labelFn = FnParser().buildWithInner(labelInline);

    // ラベル内用bigパーサー（labelInlineを使用）
    final labelBig = BigParser().buildWithInner(labelInline);

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
              labelBig | // *** は ** より先にチェック
              bold |
              boldUnder | // __ は _ より先にチェック
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
        string('***') | // big用（**より先にチェック）
        string('**') |
        string('__') | // boldUnder用（_より先にチェック）
        string('*') |
        string('_');
    final textParser = (stopper.not() & unicodeEmoji.not() & any())
        .plus()
        .flatten()
        .map(TextNode.new);
    final oneChar = any().map(TextNode.new);
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
              big | // *** は ** より先にチェック
              bold |
              boldUnder | // __ は _ より先にチェック
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
        .cast<MfmNode>()
        .plus()
        .map(mergeAdjacentTextNodes)
        .end();

    return start;
  }

  /// シンプルパーサーを構築して返す
  ///
  /// mfm-js の `parseSimple()` に相当する軽量パーサー
  /// text + unicodeEmoji + emojiCode + plain のみを解析
  ///
  /// ユーザー名表示など、パフォーマンスが重要な場面で使用を想定
  /// bold, italic, mention, hashtag 等のフォーマット構文は無視
  ///
  /// 例:
  /// - `foo **bar** baz` → `[TextNode('foo **bar** baz')]`
  /// - `abc#abc` → `[TextNode('abc#abc')]`
  /// - `Hello :wave:` → `[TextNode('Hello '), EmojiCodeNode('wave')]`
  /// - `今起きた😇` → `[TextNode('今起きた'), UnicodeEmojiNode('😇')]`
  Parser<List<MfmNode>> buildSimple() {
    // 絵文字パーサー
    final unicodeEmoji = UnicodeEmojiParser().build();
    final emojiCode = EmojiCodeParser().build();

    // plainタグパーサー（emojiCodeを内部でパースしないため必要）
    final plainTag = PlainParser().build();

    // stopper: 各構文の開始文字
    // mfm-js仕様: unicodeEmoji > emojiCode > plainTag > text
    final stopper = char(':') | string('<plain>');

    // テキストパーサー（stopper以外の文字を収集）
    final textParser = (stopper.not() & unicodeEmoji.not() & any())
        .plus()
        .flatten()
        .map(TextNode.new);

    // 1文字フォールバック
    final oneChar = any().map(TextNode.new);

    // mfm-js仕様の優先順位: unicodeEmoji > emojiCode > plainTag > text
    final simple = (unicodeEmoji | emojiCode | plainTag | textParser | oneChar)
        .cast<MfmNode>();

    return simple.plus().map(mergeAdjacentTextNodes).end();
  }
}
