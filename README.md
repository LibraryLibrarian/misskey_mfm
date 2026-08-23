# misskey_mfm_parser

[![Pub package](https://img.shields.io/pub/v/misskey_mfm_parser.svg)](https://pub.dev/packages/misskey_mfm_parser)
[![GitHub License](https://img.shields.io/badge/License-BSD-green.svg)](LICENSE)

A MFM (Markup language For Misskey) parser implementation for Dart and Flutter, built with [PetitParser](https://pub.dev/packages/petitparser).

[日本語](#日本語)

## Features

- MFM syntax support
  - Inline: bold, italic, strike, small, inline code, link, URL, mention, hashtag, emoji, MFM functions
  - Block: quote, center, code block, math block, search
- Compatible with [mfm.js](https://github.com/misskey-dev/mfm.js) parsing behavior
- Simple parser for lightweight use cases (user names, basic content)
- Full parser for complete MFM documents
- Configurable nest depth limit (same feature as [mfm.js](https://github.com/misskey-dev/mfm.js))
- Immutable AST nodes with value equality, `copyWith()`, and pattern matching support

## Getting started

dart:

```bash
dart pub add misskey_mfm_parser
```

flutter:

```bash
flutter pub add misskey_mfm_parser
```

## Usage

```dart
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

void main() {
  // Full parsing
  final parser = MfmParser().build();
  final result = parser.parse('Hello **world** @user :emoji:');
  
  if (result.isSuccess) {
    final nodes = result.value; // List<MfmNode>
    for (final node in nodes) {
      print(node);
    }
  }

  // Simple parsing (text, unicode emoji, and custom emoji only)
  final simpleParser = MfmParser().buildSimple();
  final simpleResult = simpleParser.parse('Hello 😇 :wave:');
  
  if (simpleResult.isSuccess) {
    final nodes = simpleResult.value;
    // [TextNode('Hello '), UnicodeEmojiNode('😇'), TextNode(' '), EmojiCodeNode('wave')]
  }
}
```

For more examples, see [example](example/).

## Supported Syntax

| Syntax | Node Type | Example |
|--------|-----------|---------|
| Bold | `BoldNode` | `**text**`, `<b>text</b>` |
| Italic | `ItalicNode` | `*text*`, `<i>text</i>` |
| Strike | `StrikeNode` | `~~text~~`, `<s>text</s>` |
| Small | `SmallNode` | `<small>text</small>` |
| Inline Code | `InlineCodeNode` | `` `code` `` |
| Code Block | `CodeBlockNode` | ` ```lang\ncode\n``` ` |
| Quote | `QuoteNode` | `> text` |
| Center | `CenterNode` | `<center>text</center>` |
| Link | `LinkNode` | `[label](url)` |
| URL | `UrlNode` | `https://example.com` |
| Mention | `MentionNode` | `@user`, `@user@host` |
| Hashtag | `HashtagNode` | `#tag` |
| Custom Emoji | `EmojiCodeNode` | `:emoji:` |
| Unicode Emoji | `UnicodeEmojiNode` | `😇` |
| MFM Function | `FnNode` | `$[shake text]` |
| Math (inline) | `MathInlineNode` | `\(formula\)` |
| Math (block) | `MathBlockNode` | `\[formula\]` |
| Search | `SearchNode` | `query Search` |
| Plain | `PlainNode` | `<plain>text</plain>` |

### AST compatibility note

mfm.js stores a code block's language identifier in `blockCode.props.lang`.
This package exposes the same value as `CodeBlockNode.language`; consumers
converting between the two AST representations need to map `lang` to `language`.

## Additional information

- [API Documentation](https://pub.dev/documentation/misskey_mfm_parser/latest/)
- [MFM Specification](https://misskey-hub.net/en/docs/for-users/features/mfm/)
- [mfm.js (Reference Implementation)](https://github.com/misskey-dev/mfm.js)

## License

3-Clause BSD License - see [LICENSE](LICENSE)

---

# 日本語

dart,flutter用のMFM（Markup language For Misskey）パーサー実装。
[PetitParser](https://pub.dev/packages/petitparser)を使用して構築しています。

## 特徴

- MFM構文のサポート
  - インライン: 太字、斜体、取り消し線、小文字、インラインコード、リンク、URL、メンション、ハッシュタグ、絵文字、MFM関数
  - ブロック: 引用、中央寄せ、コードブロック、数式ブロック、検索
- [mfm.js](https://github.com/misskey-dev/mfm.js)のパース動作と互換性あり
- 軽量なユースケース向けのシンプルパーサー（ユーザー名表示など）
- 完全なMFMドキュメント用のフルパーサー
- ネスト深度制限の設定が可能（[mfm.js](https://github.com/misskey-dev/mfm.js)と同じ機能）
- 値の等価性、`copyWith()`、パターンマッチングをサポートするイミュータブルなASTノード

## インストール

dart:

```bash
dart pub add misskey_mfm_parser
```

flutter:

```bash
flutter pub add misskey_mfm_parser
```

## 使い方

```dart
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

void main() {
  // フルパース
  final parser = MfmParser().build();
  final result = parser.parse('こんにちは **世界** @user :emoji:');
  
  if (result.isSuccess) {
    final nodes = result.value; // List<MfmNode>
    for (final node in nodes) {
      print(node);
    }
  }

  // シンプルパース（テキスト、Unicode絵文字、カスタム絵文字のみ）
  final simpleParser = MfmParser().buildSimple();
  final simpleResult = simpleParser.parse('こんにちは 😇 :wave:');
  
  if (simpleResult.isSuccess) {
    final nodes = simpleResult.value;
    // [TextNode('こんにちは '), UnicodeEmojiNode('😇'), TextNode(' '), EmojiCodeNode('wave')]
  }
}
```

詳細な例は [example](example/) に記載しています。

## 対応構文

| 構文 | ノードタイプ | 例 |
|------|-------------|-----|
| 太字 | `BoldNode` | `**text**`, `<b>text</b>` |
| 斜体 | `ItalicNode` | `*text*`, `<i>text</i>` |
| 取り消し線 | `StrikeNode` | `~~text~~`, `<s>text</s>` |
| 小文字 | `SmallNode` | `<small>text</small>` |
| インラインコード | `InlineCodeNode` | `` `code` `` |
| コードブロック | `CodeBlockNode` | ` ```lang\ncode\n``` ` |
| 引用 | `QuoteNode` | `> text` |
| 中央寄せ | `CenterNode` | `<center>text</center>` |
| リンク | `LinkNode` | `[label](url)` |
| URL | `UrlNode` | `https://example.com` |
| メンション | `MentionNode` | `@user`, `@user@host` |
| ハッシュタグ | `HashtagNode` | `#tag` |
| カスタム絵文字 | `EmojiCodeNode` | `:emoji:` |
| Unicode絵文字 | `UnicodeEmojiNode` | `😇` |
| MFM関数 | `FnNode` | `$[shake text]` |
| 数式（インライン） | `MathInlineNode` | `\(formula\)` |
| 数式（ブロック） | `MathBlockNode` | `\[formula\]` |
| 検索 | `SearchNode` | `query Search` |
| プレーン | `PlainNode` | `<plain>text</plain>` |

### AST互換性に関する注意

mfm.js はコードブロックの言語識別子を `blockCode.props.lang` に格納します。
本パッケージでは同じ値を `CodeBlockNode.language` として公開しているため、
両AST表現を相互変換する場合は `lang` と `language` を対応付けてください。

## 追加情報

- [APIドキュメント](https://pub.dev/documentation/misskey_mfm_parser/latest/)
- [MFM仕様](https://misskey-hub.net/ja/docs/for-users/features/mfm/)
- [mfm.js（リファレンス実装）](https://github.com/misskey-dev/mfm.js)

## ライセンス

3-Clause BSD License - [LICENSE](LICENSE) を参照
