import 'package:freezed_annotation/freezed_annotation.dart';

part 'ast.freezed.dart';

/// Base class for MFM (Misskey Flavored Markdown) Abstract Syntax Tree nodes.
///
/// MFM（Misskey Flavored Markdown）の抽象構文木（AST）の基底クラス
@freezed
sealed class MfmNode with _$MfmNode {
  const MfmNode._();

  /// Plain text.
  ///
  /// プレーンテキスト
  const factory MfmNode.text(String text) = TextNode;

  /// Inline code (`` ` ... ` ``).
  ///
  /// インラインコード（` ... `）
  const factory MfmNode.inlineCode(String code) = InlineCodeNode;

  /// Custom emoji (`:name:`).
  ///
  /// カスタム絵文字 :name:
  const factory MfmNode.emojiCode(String name) = EmojiCodeNode;

  /// Unicode emoji.
  ///
  /// Unicode絵文字
  const factory MfmNode.unicodeEmoji(String emoji) = UnicodeEmojiNode;

  /// Hashtag (`#tag`).
  ///
  /// ハッシュタグ #tag
  const factory MfmNode.hashtag(String hashtag) = HashtagNode;

  /// Math block (`\[formula\]`).
  ///
  /// Displays a LaTeX-formatted formula as a block.
  /// `\[` must be at the start of the line and `\]` at the end.
  ///
  /// LaTeX形式の数式をブロックとして表示
  /// `\[` は行頭、`\]` は行末である必要がある
  const factory MfmNode.mathBlock(String formula) = MathBlockNode;

  /// Inline math (`\(formula\)`).
  ///
  /// Displays a LaTeX-formatted formula inline.
  /// Newlines are not allowed.
  ///
  /// LaTeX形式の数式をインラインで表示
  /// 改行を含めることはできない
  const factory MfmNode.mathInline(String formula) = MathInlineNode;

  /// Bold text (`** ... **`).
  ///
  /// 太字（** ... **）
  const factory MfmNode.bold(List<MfmNode> children) = BoldNode;

  /// Italic text (`* ... *` or `<i>...</i>`).
  ///
  /// 斜体（* ... *）または<i> ... </i>
  const factory MfmNode.italic(List<MfmNode> children) = ItalicNode;

  /// Strikethrough text (`~~ ... ~~` or `<s>...</s>`).
  ///
  /// 取り消し線（~~ ... ~~）または<s> ... </s>
  const factory MfmNode.strike(List<MfmNode> children) = StrikeNode;

  /// Small text (`<small>...</small>`).
  ///
  /// 小文字（<small> ... </small>）
  const factory MfmNode.small(List<MfmNode> children) = SmallNode;

  /// Quote (lines starting with `> `).
  ///
  /// 引用（行頭の "> "）
  const factory MfmNode.quote(List<MfmNode> children) = QuoteNode;

  /// Centered content (`<center>...</center>`).
  ///
  /// 中央寄せ（&lt;center&gt; ... &lt;/center&gt;）
  const factory MfmNode.center(List<MfmNode> children) = CenterNode;

  /// Plain text segment with parsing disabled.
  ///
  /// パースを無効化するプレーンテキストセグメント
  const factory MfmNode.plain(List<MfmNode> children) = PlainNode;

  /// Auto-linked URL (`https://...` or `<https://...>`).
  ///
  /// URL自動リンク https://... または <https://...>
  const factory MfmNode.url({
    /// The URL string.
    ///
    /// URL文字列
    required String url,

    /// Whether this uses bracket format (`<url>`).
    ///
    /// ブラケット形式（&lt;url&gt;）かどうか
    @Default(false) bool brackets,
  }) = UrlNode;

  /// Link ([`label`](url) or `?[label](url)`).
  ///
  /// リンク [label](url) / ?[label](url)
  const factory MfmNode.link({
    /// Whether this is a silent link (has `?` prefix).
    ///
    /// サイレントリンクかどうか（?プレフィックスの有無）
    required bool silent,

    /// The destination URL.
    ///
    /// リンク先URL
    required String url,

    /// List of child nodes (link text).
    ///
    /// 子ノードのリスト（リンクテキスト）
    required List<MfmNode> children,
  }) = LinkNode;

  /// Mention (`@user` or `@user@host`).
  ///
  /// メンション @user または @user@host
  const factory MfmNode.mention({
    /// The username.
    ///
    /// ユーザー名
    required String username,

    /// The host (optional, for remote users).
    ///
    /// ホスト（省略可、リモートユーザー用）
    String? host,

    /// The full account identifier (e.g., `@user` or `@user@host`).
    ///
    /// 完全なアカウント識別子（例: `@user` または `@user@host`）
    required String acct,
  }) = MentionNode;

  /// MFM function (`$[name.args content]`).
  ///
  /// MFM functions apply animation and visual effects to text.
  /// Examples: $[shake 🍮], $[spin.speed=2s text], $[flip.h,v content]
  ///
  /// MFM関数はテキストにアニメーションや視覚効果を付与する機能
  /// 例: $[shake 🍮], $[spin.speed=2s text], $[flip.h,v content]
  const factory MfmNode.fn({
    /// The function name (e.g., tada, shake, spin).
    ///
    /// 関数名（tada, shake, spin等）
    required String name,

    /// Arguments map (key: String value or true).
    ///
    /// Example: {speed: "2s", h: true, v: true}
    ///
    /// 引数マップ（key: String値またはtrue）
    ///
    /// 例: {speed: "2s", h: true, v: true}
    required Map<String, dynamic> args,

    /// List of child nodes (content to apply the function to).
    ///
    /// 子ノードのリスト（関数に適用される内容）
    required List<MfmNode> children,
  }) = FnNode;

  /// Code block (`` ``` ... ``` ``).
  ///
  /// コードブロック（``` ... ```）
  const factory MfmNode.codeBlock({
    /// The code content (supports multiple lines).
    ///
    /// コード内容（複数行対応）
    required String code,

    /// The language (optional).
    ///
    /// 言語（省略可）
    String? language,
  }) = CodeBlockNode;

  /// Search block (`query Search`).
  ///
  /// Formats: `query Search`, `query 検索`, `query [Search]`, `query [検索]`.
  /// Case-insensitive.
  ///
  /// 形式: `query Search`、`query 検索`、`query [Search]`、`query [検索]`
  /// 大文字小文字は区別されない
  const factory MfmNode.search({
    /// The search query (keyword part).
    ///
    /// 検索クエリ（検索キーワード部分）
    required String query,

    /// The original input text (query + space + search button).
    ///
    /// 元の入力テキスト全体（クエリ + スペース + 検索ボタン）
    required String content,
  }) = SearchNode;
}
