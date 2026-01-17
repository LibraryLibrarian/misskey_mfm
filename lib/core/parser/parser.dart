import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'block/center.dart';
import 'block/code_block.dart';
import 'block/math_block.dart';
import 'block/quote.dart';
import 'block/search.dart';
import 'common/utils.dart';
import 'core/nest.dart';
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
  /// デフォルトのネスト制限値
  static const defaultNestLimit = 20;

  /// パーサーを構築して返す
  ///
  /// [nestLimit] ネストの深さ制限（デフォルト: 20）
  /// mfm-js互換: ネスト深度がlimitに達すると、それ以上のネスト構文はテキストとして扱われる
  Parser<List<MfmNode>> build({int? nestLimit}) {
    // ネスト状態を共有（nullの場合はデフォルト値を使用）
    final nestState = NestState(limit: nestLimit ?? defaultNestLimit);
    final inline = undefined<MfmNode>();

    // big構文（廃止予定だが後方互換性のため実装）
    // *** は ** より先にチェックする必要がある
    final big = BigParser().buildWithInner(inline, state: nestState);
    final bold = BoldParser().buildWithInner(inline, state: nestState);
    final boldTag = BoldParser().buildTagWithInner(inline, state: nestState);
    // __ は _ より先にチェックする必要がある
    final boldUnder = BoldParser().buildUnder();
    final italicAsterisk = ItalicParser().buildWithInner(
      inline,
      state: nestState,
    );
    final italicTag = ItalicParser().buildTagWithInner(
      inline,
      state: nestState,
    );
    final italicAlt2 = ItalicParser().buildAlt2();
    final smallTag = SmallParser().buildWithInner(inline, state: nestState);
    final strike = StrikeParser().buildWithInner(inline, state: nestState);
    final strikeTag = StrikeParser().buildTagWithInner(
      inline,
      state: nestState,
    );
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
    final url = UrlParser().buildWithFallback(state: nestState);
    final urlAlt = UrlParser().buildAlt();

    // MFM関数パーサー
    final fn = FnParser().buildWithInner(inline, state: nestState);

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

    // ラベル内用パーサー（labelInlineを使用）
    // mfm-js仕様: リンクラベル内ではURL、リンク、メンションは無効
    // そのため、ネスト構文内でもlabelInlineを使用する必要がある
    final labelFn = FnParser().buildWithInner(labelInline, state: nestState);
    final labelBig = BigParser().buildWithInner(labelInline, state: nestState);
    final labelBold = BoldParser().buildWithInner(
      labelInline,
      state: nestState,
    );
    final labelBoldTag = BoldParser().buildTagWithInner(
      labelInline,
      state: nestState,
    );
    final labelItalicAsterisk = ItalicParser().buildWithInner(
      labelInline,
      state: nestState,
    );
    final labelItalicTag = ItalicParser().buildTagWithInner(
      labelInline,
      state: nestState,
    );
    final labelSmallTag = SmallParser().buildWithInner(
      labelInline,
      state: nestState,
    );
    final labelStrike = StrikeParser().buildWithInner(
      labelInline,
      state: nestState,
    );
    final labelStrikeTag = StrikeParser().buildTagWithInner(
      labelInline,
      state: nestState,
    );

    labelInline.set(
      (inlineCode |
              unicodeEmoji |
              emojiCode |
              // mfm-js仕様: リンクラベル内ではメンション、ハッシュタグ、URL、リンクは無効
              labelFn | // fn はリンクラベル内でも有効
              plainTag | // <plain>...</plain> 形式
              labelSmallTag |
              labelStrikeTag |
              labelBoldTag |
              labelItalicTag |
              labelStrike |
              labelBig | // *** は ** より先にチェック
              labelBold |
              boldUnder | // __ は _ より先にチェック
              italicAlt2 |
              labelItalicAsterisk |
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
    final center = CenterParser().buildWithInner(inline, state: nestState);
    final search = SearchParser().build();

    // fullParserはblocks + inlineの組み合わせ（quote内で再帰的に使用）
    final full = undefined<MfmNode>();

    // mfm-js互換: quoteはfullParser（blocks + inline）を内部でパース
    final quote = QuoteParser().buildWithInner(full, state: nestState);

    final blocks = codeBlock | mathBlock | center | quote | search;

    // fullをblocks | inlineに設定（循環参照を解決）
    full.set((blocks | inline).cast<MfmNode>());

    final start = full.plus().map(mergeAdjacentTextNodes).end();

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
