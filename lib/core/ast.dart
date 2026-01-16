/// MFM（Misskey Flavored Markdown）の抽象構文木（AST）の基底クラス
abstract class MfmNode {
  const MfmNode();
}

/// リーフノード：プレーンテキストを表す
class TextNode extends MfmNode {
  const TextNode(this.text);

  /// テキスト内容
  final String text;
}

/// インラインノード：太字（** ... **）を表す
class BoldNode extends MfmNode {
  const BoldNode(this.children);

  /// 子ノードのリスト
  final List<MfmNode> children;
}

/// インラインノード：斜体（* ... *）または<i> ... </i>を表す
class ItalicNode extends MfmNode {
  const ItalicNode(this.children);

  /// 子ノードのリスト
  final List<MfmNode> children;
}

/// インラインノード：取り消し線（~~ ... ~~）または<s> ... </s>を表す
class StrikeNode extends MfmNode {
  const StrikeNode(this.children);

  /// 子ノードのリスト
  final List<MfmNode> children;
}

/// インラインノード：小文字（<small> ... </small>）を表す
class SmallNode extends MfmNode {
  const SmallNode(this.children);

  /// 子ノードのリスト
  final List<MfmNode> children;
}

/// ブロックノード：引用（行頭の "> "）を表す
class QuoteNode extends MfmNode {
  const QuoteNode(this.children);

  /// 子ノードのリスト（引用の内容）
  final List<MfmNode> children;
}

/// ブロックノード：中央寄せ（&lt;center&gt; ... &lt;/center&gt;）を表す
class CenterNode extends MfmNode {
  const CenterNode(this.children);

  /// 子ノードのリスト（中央寄せ内の内容）
  final List<MfmNode> children;
}

/// インラインノード：インラインコード（` ... `）を表す
class InlineCodeNode extends MfmNode {
  const InlineCodeNode(this.code);

  /// コード内容（プレーンテキスト）
  final String code;
}

/// インラインノード：リンク [label](url) / ?[label](url)を表す
class LinkNode extends MfmNode {
  const LinkNode({
    required this.silent,
    required this.url,
    required this.children,
  });

  /// サイレントリンクかどうか（?プレフィックスの有無）
  final bool silent;

  /// リンク先URL
  final String url;

  /// 子ノードのリスト（リンクテキスト）
  final List<MfmNode> children;
}

/// インラインノード：URL自動リンク https://... または <https://...>を表す
class UrlNode extends MfmNode {
  const UrlNode({required this.url, this.brackets = false});

  /// URL文字列
  final String url;

  /// ブラケット形式（&lt;url&gt;）かどうか
  final bool brackets;
}

/// インラインノード：メンション @user または @user@hostを表す
class MentionNode extends MfmNode {
  const MentionNode({required this.username, this.host, required this.acct});

  /// ユーザー名
  final String username;

  /// ホスト名（リモートユーザーの場合）
  final String? host;

  /// アカウント識別子（username@host形式）
  final String acct;
}

/// インラインノード：ハッシュタグ #tagを表す
class HashtagNode extends MfmNode {
  const HashtagNode(this.hashtag);

  /// ハッシュタグ名
  final String hashtag;
}

/// インラインノード：カスタム絵文字 :name:を表す
class EmojiCodeNode extends MfmNode {
  const EmojiCodeNode(this.name);

  /// 絵文字名
  final String name;
}

/// インラインノード：Unicode絵文字を表す
class UnicodeEmojiNode extends MfmNode {
  const UnicodeEmojiNode(this.emoji);

  /// 絵文字文字列
  final String emoji;
}

/// インラインノード：パースを無効化するプレーンテキストセグメントを表す
class PlainNode extends MfmNode {
  const PlainNode(this.children);

  /// 子ノードのリスト
  final List<MfmNode> children;
}

/// ブロックノード：コードブロック（``` ... ```）を表す
class CodeBlockNode extends MfmNode {
  const CodeBlockNode({required this.code, this.language});

  /// コード内容（複数行対応）
  final String code;

  /// 言語（省略可）
  final String? language;
}
