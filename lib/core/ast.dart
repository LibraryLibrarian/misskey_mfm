/// MFM（Misskey Flavored Markdown）の抽象構文木（AST）の基底クラス
abstract class MfmNode {
  const MfmNode();
}

/// リーフノード：プレーンテキストを表す
class TextNode extends MfmNode {
  /// テキスト内容
  final String text;
  const TextNode(this.text);
}

/// インラインノード：太字（** ... **）を表す
class BoldNode extends MfmNode {
  /// 子ノードのリスト
  final List<MfmNode> children;
  const BoldNode(this.children);
}

/// インラインノード：斜体（* ... *）または<i> ... </i>を表す
class ItalicNode extends MfmNode {
  /// 子ノードのリスト
  final List<MfmNode> children;
  const ItalicNode(this.children);
}

/// インラインノード：取り消し線（~~ ... ~~）または<s> ... </s>を表す
class StrikeNode extends MfmNode {
  /// 子ノードのリスト
  final List<MfmNode> children;
  const StrikeNode(this.children);
}

/// インラインノード：小文字（<small> ... </small>）を表す
class SmallNode extends MfmNode {
  /// 子ノードのリスト
  final List<MfmNode> children;
  const SmallNode(this.children);
}

/// ブロックノード：引用（行頭の "> "）を表す
class QuoteNode extends MfmNode {
  /// 子ノードのリスト（引用の内容）
  final List<MfmNode> children;
  const QuoteNode(this.children);
}

/// インラインノード：リンク [label](url) / ?[label](url)を表す
class LinkNode extends MfmNode {
  /// サイレントリンクかどうか（?プレフィックスの有無）
  final bool silent;

  /// リンク先URL
  final String url;

  /// 子ノードのリスト（リンクテキスト）
  final List<MfmNode> children;
  const LinkNode({
    required this.silent,
    required this.url,
    required this.children,
  });
}

/// インラインノード：メンション @user または @user@hostを表す
class MentionNode extends MfmNode {
  /// ユーザー名
  final String username;

  /// ホスト名（リモートユーザーの場合）
  final String? host;

  /// アカウント識別子（username@host形式）
  final String acct;
  const MentionNode({required this.username, this.host, required this.acct});
}

/// インラインノード：ハッシュタグ #tagを表す
class HashtagNode extends MfmNode {
  /// ハッシュタグ名
  final String hashtag;
  const HashtagNode(this.hashtag);
}

/// インラインノード：カスタム絵文字 :name:を表す
class EmojiCodeNode extends MfmNode {
  /// 絵文字名
  final String name;
  const EmojiCodeNode(this.name);
}

/// インラインノード：Unicode絵文字を表す
class UnicodeEmojiNode extends MfmNode {
  /// 絵文字文字列
  final String emoji;
  const UnicodeEmojiNode(this.emoji);
}

/// インラインノード：パースを無効化するプレーンテキストセグメントを表す
class PlainNode extends MfmNode {
  /// 子ノードのリスト
  final List<MfmNode> children;
  const PlainNode(this.children);
}
