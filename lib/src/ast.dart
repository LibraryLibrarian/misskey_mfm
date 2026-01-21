/// Base class for MFM (Misskey Flavored Markdown) Abstract Syntax Tree nodes.
///
/// MFM（Misskey Flavored Markdown）の抽象構文木（AST）の基底クラス
abstract class MfmNode {
  const MfmNode();
}

/// Leaf node representing plain text.
///
/// リーフノード：プレーンテキストを表す
class TextNode extends MfmNode {
  const TextNode(this.text);

  /// The text content.
  ///
  /// テキスト内容
  final String text;
}

/// Inline node representing bold text (`** ... **`).
///
/// インラインノード：太字（** ... **）を表す
class BoldNode extends MfmNode {
  const BoldNode(this.children);

  /// List of child nodes.
  ///
  /// 子ノードのリスト
  final List<MfmNode> children;
}

/// Inline node representing italic text (`* ... *` or `<i>...</i>`).
///
/// インラインノード：斜体（* ... *）または<i> ... </i>を表す
class ItalicNode extends MfmNode {
  const ItalicNode(this.children);

  /// List of child nodes.
  ///
  /// 子ノードのリスト
  final List<MfmNode> children;
}

/// Inline node representing strikethrough text (`~~ ... ~~` or `<s>...</s>`).
///
/// インラインノード：取り消し線（~~ ... ~~）または<s> ... </s>を表す
class StrikeNode extends MfmNode {
  const StrikeNode(this.children);

  /// List of child nodes.
  ///
  /// 子ノードのリスト
  final List<MfmNode> children;
}

/// Inline node representing small text (`<small>...</small>`).
///
/// インラインノード：小文字（<small> ... </small>）を表す
class SmallNode extends MfmNode {
  const SmallNode(this.children);

  /// List of child nodes.
  ///
  /// 子ノードのリスト
  final List<MfmNode> children;
}

/// Block node representing a quote (lines starting with `> `).
///
/// ブロックノード：引用（行頭の "> "）を表す
class QuoteNode extends MfmNode {
  const QuoteNode(this.children);

  /// List of child nodes (quote content).
  ///
  /// 子ノードのリスト（引用の内容）
  final List<MfmNode> children;
}

/// Block node representing centered content (`<center>...</center>`).
///
/// ブロックノード：中央寄せ（&lt;center&gt; ... &lt;/center&gt;）を表す
class CenterNode extends MfmNode {
  const CenterNode(this.children);

  /// List of child nodes (centered content).
  ///
  /// 子ノードのリスト（中央寄せ内の内容）
  final List<MfmNode> children;
}

/// Inline node representing inline code (`` ` ... ` ``).
///
/// インラインノード：インラインコード（` ... `）を表す
class InlineCodeNode extends MfmNode {
  const InlineCodeNode(this.code);

  /// The code content (plain text).
  ///
  /// コード内容（プレーンテキスト）
  final String code;
}

/// Inline node representing a link ([`label`](url) or `?[label](url)`).
///
/// インラインノード：リンク [label](url) / ?[label](url)を表す
class LinkNode extends MfmNode {
  const LinkNode({
    required this.silent,
    required this.url,
    required this.children,
  });

  /// Whether this is a silent link (has `?` prefix).
  ///
  /// サイレントリンクかどうか（?プレフィックスの有無）
  final bool silent;

  /// The destination URL.
  ///
  /// リンク先URL
  final String url;

  /// List of child nodes (link text).
  ///
  /// 子ノードのリスト（リンクテキスト）
  final List<MfmNode> children;
}

/// Inline node representing an auto-linked URL (`https://...` or `<https://...>`).
///
/// インラインノード：URL自動リンク https://... または <https://...>を表す
class UrlNode extends MfmNode {
  const UrlNode({required this.url, this.brackets = false});

  /// The URL string.
  ///
  /// URL文字列
  final String url;

  /// Whether this uses bracket format (`<url>`).
  ///
  /// ブラケット形式（&lt;url&gt;）かどうか
  final bool brackets;
}

/// Inline node representing a mention (`@user` or `@user@host`).
///
/// インラインノード：メンション @user または @user@hostを表す
class MentionNode extends MfmNode {
  const MentionNode({required this.username, this.host, required this.acct});

  /// The username.
  ///
  /// ユーザー名
  final String username;

  /// The host (for remote users).
  ///
  /// ホスト名（リモートユーザーの場合）
  final String? host;

  /// The account identifier (`username@host` format).
  ///
  /// アカウント識別子（username@host形式）
  final String acct;
}

/// Inline node representing a hashtag (`#tag`).
///
/// インラインノード：ハッシュタグ #tagを表す
class HashtagNode extends MfmNode {
  const HashtagNode(this.hashtag);

  /// The hashtag name.
  ///
  /// ハッシュタグ名
  final String hashtag;
}

/// Inline node representing a custom emoji (`:name:`).
///
/// インラインノード：カスタム絵文字 :name:を表す
class EmojiCodeNode extends MfmNode {
  const EmojiCodeNode(this.name);

  /// The emoji name.
  ///
  /// 絵文字名
  final String name;
}

/// Inline node representing a Unicode emoji.
///
/// インラインノード：Unicode絵文字を表す
class UnicodeEmojiNode extends MfmNode {
  const UnicodeEmojiNode(this.emoji);

  /// The emoji string.
  ///
  /// 絵文字文字列
  final String emoji;
}

/// Inline node representing a plain text segment with parsing disabled.
///
/// インラインノード：パースを無効化するプレーンテキストセグメントを表す
class PlainNode extends MfmNode {
  const PlainNode(this.children);

  /// List of child nodes.
  ///
  /// 子ノードのリスト
  final List<MfmNode> children;
}

/// Block node representing a code block (`` ``` ... ``` ``).
///
/// ブロックノード：コードブロック（``` ... ```）を表す
class CodeBlockNode extends MfmNode {
  const CodeBlockNode({required this.code, this.language});

  /// The code content (supports multiple lines).
  ///
  /// コード内容（複数行対応）
  final String code;

  /// The language (optional).
  ///
  /// 言語（省略可）
  final String? language;
}

/// Inline node representing an MFM function (`$[name.args content]`).
///
/// MFM functions apply animation and visual effects to text.
/// Examples: $[shake 🍮], $[spin.speed=2s text], $[flip.h,v content]
///
/// MFM関数はテキストにアニメーションや視覚効果を付与する機能
/// 例: $[shake 🍮], $[spin.speed=2s text], $[flip.h,v content]
class FnNode extends MfmNode {
  const FnNode({
    required this.name,
    required this.args,
    required this.children,
  });

  /// The function name (e.g., tada, shake, spin).
  ///
  /// 関数名（tada, shake, spin等）
  final String name;

  /// Arguments map (key: String value or true).
  ///
  /// Example: {speed: "2s", h: true, v: true}
  ///
  /// 引数マップ（key: String値またはtrue）
  ///
  /// 例: {speed: "2s", h: true, v: true}
  final Map<String, dynamic> args;

  /// List of child nodes (content to apply the function to).
  ///
  /// 子ノードのリスト（関数に適用される内容）
  final List<MfmNode> children;
}

/// Block node representing a search block (`query Search`).
///
/// Formats: `query Search`, `query 検索`, `query [Search]`, `query [検索]`.
/// Case-insensitive.
///
/// 形式: `query Search`、`query 検索`、`query [Search]`、`query [検索]`
/// 大文字小文字は区別されない
class SearchNode extends MfmNode {
  const SearchNode({required this.query, required this.content});

  /// The search query (keyword part).
  ///
  /// 検索クエリ（検索キーワード部分）
  final String query;

  /// The original input text (query + space + search button).
  ///
  /// 元の入力テキスト全体（クエリ + スペース + 検索ボタン）
  final String content;
}

/// Block node representing a math block (`\[formula\]`).
///
/// Displays a LaTeX-formatted formula as a block.
/// `\[` must be at the start of the line and `\]` at the end.
///
/// LaTeX形式の数式をブロックとして表示
/// `\[` は行頭、`\]` は行末である必要がある
class MathBlockNode extends MfmNode {
  const MathBlockNode(this.formula);

  /// The formula (LaTeX format).
  ///
  /// 数式（LaTeX形式）
  final String formula;
}

/// Inline node representing inline math (`\(formula\)`).
///
/// Displays a LaTeX-formatted formula inline.
/// Newlines are not allowed.
///
/// LaTeX形式の数式をインラインで表示
/// 改行を含めることはできない
class MathInlineNode extends MfmNode {
  const MathInlineNode(this.formula);

  /// The formula (LaTeX format).
  ///
  /// 数式（LaTeX形式）
  final String formula;
}
