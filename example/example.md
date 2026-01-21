# misskey_mfm_parser Examples

This document demonstrates how to use the `misskey_mfm_parser` package.

[日本語](#日本語)

## Table of Contents

- [Full Parser](#full-parser)
- [Simple Parser](#simple-parser)
- [Nest Limit Customization](#nest-limit-customization)
- [Node Type Handling](#node-type-handling)
- [Node Types Reference](#node-types-reference)

---

## Full Parser

The full parser supports all MFM syntax including inline styles, mentions, hashtags, URLs, MFM functions, and block elements.

```dart
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

void main() {
  final parser = MfmParser().build();

  const input = '''
Hello **bold** and *italic* text!
@user@example.com mentioned you
Check out #misskey
Visit https://misskey.io
:custom_emoji: and 😇
\$[shake 🍮]
> This is a quote
''';

  final result = parser.parse(input);

  if (result.isSuccess) {
    final nodes = result.value; // List<MfmNode>
    print('Parsed ${nodes.length} nodes');
    
    for (final node in nodes) {
      print('  - ${node.runtimeType}');
    }
  } else {
    print('Parse error: ${result.message}');
  }
}
```

**Output:**

```
Parsed 15 nodes
  - TextNode
  - BoldNode
  - TextNode
  - ItalicNode
  - TextNode
  - MentionNode
  - TextNode
  - HashtagNode
  - TextNode
  - UrlNode
  - TextNode
  - EmojiCodeNode
  - TextNode
  - UnicodeEmojiNode
  - TextNode
  - FnNode
  - TextNode
  - QuoteNode
```

---

## Simple Parser

The simple parser is a lightweight parser that only recognizes:

- Plain text
- Unicode emoji (e.g., `😇`, `🎉`)
- Custom emoji codes (e.g., `:wave:`, `:misskey:`)
- Plain tags (`<plain>...</plain>`)

All other MFM syntax (bold, italic, mentions, hashtags, URLs, etc.) is treated as plain text.

**Use cases:**
- Displaying user names
- Notification previews
- Performance-critical scenarios where full parsing is not needed

```dart
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

void main() {
  final simpleParser = MfmParser().buildSimple();

  const input = 'Hello 😇 :wave: **not bold** @user #tag';

  final result = simpleParser.parse(input);

  if (result.isSuccess) {
    for (final node in result.value) {
      switch (node) {
        case TextNode(:final text):
          print('TextNode: "$text"');
        case UnicodeEmojiNode(:final emoji):
          print('UnicodeEmojiNode: $emoji');
        case EmojiCodeNode(:final name):
          print('EmojiCodeNode: :$name:');
        default:
          print('${node.runtimeType}');
      }
    }
  }
}
```

**Output:**

```
TextNode: "Hello "
UnicodeEmojiNode: 😇
TextNode: " "
EmojiCodeNode: :wave:
TextNode: " **not bold** @user #tag"
```

Notice that `**not bold**`, `@user`, and `#tag` are treated as plain text.

---

## Nest Limit Customization

MFM allows nested structures (e.g., bold inside italic inside a link).  
To prevent excessive nesting and potential performance issues, you can configure the nest limit. (We recommend using the default value to avoid differences from Misskey unless there is a specific reason.)

- **Default:** 20 (same as mfm.js)
- When the nest depth reaches the limit, nested syntax will be processed as plain text

```dart
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

void main() {
  // Create parser with custom nest limit
  final parser = MfmParser().build(nestLimit: 5);

  const input = '**bold *italic ~~strike **deeper** strike~~ italic* bold**';
  
  final result = parser.parse(input);

  if (result.isSuccess) {
    printNodes(result.value);
  }
}

void printNodes(List<MfmNode> nodes, {int indent = 0}) {
  final prefix = '  ' * indent;
  for (final node in nodes) {
    switch (node) {
      case TextNode(:final text):
        print('$prefix TextNode: "$text"');
      case BoldNode(:final children):
        print('${prefix}BoldNode:');
        printNodes(children, indent: indent + 1);
      case ItalicNode(:final children):
        print('${prefix}ItalicNode:');
        printNodes(children, indent: indent + 1);
      case StrikeNode(:final children):
        print('${prefix}StrikeNode:');
        printNodes(children, indent: indent + 1);
      default:
        print('$prefix${node.runtimeType}');
    }
  }
}
```

---

## Node Type Handling

When rendering or processing parsed MFM, you need to handle each node type appropriately. Here's an example:

```dart
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

void main() {
  final parser = MfmParser().build();
  
  const input = '''
**Welcome** to @alice@example.com's post!
Check #flutter and visit https://flutter.dev
Here's some code: `print("Hello")`
\$[spin 🌟]
''';

  final result = parser.parse(input);

  if (result.isSuccess) {
    for (final node in result.value) {
      processNode(node);
    }
  }
}

void processNode(MfmNode node, {int indent = 0}) {
  final prefix = '  ' * indent;

  switch (node) {
    // Leaf nodes (no children)
    case TextNode(:final text):
      print('${prefix}Text: "$text"');

    case UnicodeEmojiNode(:final emoji):
      print('${prefix}UnicodeEmoji: $emoji');

    case EmojiCodeNode(:final name):
      print('${prefix}CustomEmoji: :$name:');

    case MentionNode(:final username, :final host, :final acct):
      print('${prefix}Mention: @$acct (user=$username, host=$host)');

    case HashtagNode(:final hashtag):
      print('${prefix}Hashtag: #$hashtag');

    case UrlNode(:final url, :final brackets):
      print('${prefix}URL: $url (brackets=$brackets)');

    case InlineCodeNode(:final code):
      print('${prefix}InlineCode: `$code`');

    case CodeBlockNode(:final code, :final language):
      print('${prefix}CodeBlock (lang=${language ?? "none"}):');
      print('$prefix  $code');

    case MathInlineNode(:final formula):
      print('${prefix}MathInline: \\($formula\\)');

    case MathBlockNode(:final formula):
      print('${prefix}MathBlock: \\[$formula\\]');

    case SearchNode(:final query, :final content):
      print('${prefix}Search: query="$query", content="$content"');

    // Container nodes (with children)
    case BoldNode(:final children):
      print('${prefix}Bold:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case ItalicNode(:final children):
      print('${prefix}Italic:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case StrikeNode(:final children):
      print('${prefix}Strike:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case SmallNode(:final children):
      print('${prefix}Small:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case CenterNode(:final children):
      print('${prefix}Center:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case QuoteNode(:final children):
      print('${prefix}Quote:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case PlainNode(:final children):
      print('${prefix}Plain:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case LinkNode(:final url, :final silent, :final children):
      print('${prefix}Link (url=$url, silent=$silent):');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case FnNode(:final name, :final args, :final children):
      print('${prefix}Function \$[$name${_formatArgs(args)}]:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }
  }
}

String _formatArgs(Map<String, dynamic> args) {
  if (args.isEmpty) return '';
  
  final parts = args.entries.map((e) {
    if (e.value == true) return e.key;
    return '${e.key}=${e.value}';
  });
  
  return '.${parts.join(",")}';
}
```

**Output:**

```
Bold:
  Text: "Welcome"
Text: " to "
Mention: @alice@example.com (user=alice, host=example.com)
Text: "'s post!
Check "
Hashtag: #flutter
Text: " and visit "
URL: https://flutter.dev (brackets=false)
Text: "
Here's some code: "
InlineCode: `print("Hello")`
Text: "
"
Function $[spin]:
  UnicodeEmoji: 🌟
Text: "
"
```

---

## Node Types Reference

| Node Type | Has Children | Description |
|-----------|--------------|-------------|
| `TextNode` | No | Plain text |
| `UnicodeEmojiNode` | No | Unicode emoji (e.g., 😇) |
| `EmojiCodeNode` | No | Custom emoji (e.g., :wave:) |
| `MentionNode` | No | User mention (@user or @user@host) |
| `HashtagNode` | No | Hashtag (#tag) |
| `UrlNode` | No | URL (https://...) |
| `InlineCodeNode` | No | Inline code (\`code\`) |
| `CodeBlockNode` | No | Code block (\`\`\`code\`\`\`) |
| `MathInlineNode` | No | Inline math (\\(formula\\)) |
| `MathBlockNode` | No | Block math (\\[formula\\]) |
| `SearchNode` | No | Search block |
| `BoldNode` | Yes | Bold text (\*\*text\*\*) |
| `ItalicNode` | Yes | Italic text (\*text\*) |
| `StrikeNode` | Yes | Strikethrough (\~\~text\~\~) |
| `SmallNode` | Yes | Small text (\<small\>text\</small\>) |
| `CenterNode` | Yes | Centered text (\<center\>text\</center\>) |
| `QuoteNode` | Yes | Quote block (> text) |
| `PlainNode` | Yes | Plain block (\<plain\>text\</plain\>) |
| `LinkNode` | Yes | Link (\[label\](url)) |
| `FnNode` | Yes | MFM function ($[name content]) |

---

# 日本語

このドキュメントでは `misskey_mfm_parser` パッケージの使い方を説明します。

## 目次

- [フルパーサー](#フルパーサー)
- [シンプルパーサー](#シンプルパーサー)
- [ネスト制限のカスタマイズ](#ネスト制限のカスタマイズ)
- [ノードタイプ別の処理](#ノードタイプ別の処理)
- [ノードタイプ一覧](#ノードタイプ一覧)

---

## フルパーサー

フルパーサーは、インラインスタイル、メンション、ハッシュタグ、URL、MFM関数、ブロック要素など、すべてのMFM構文をサポートします。

```dart
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

void main() {
  final parser = MfmParser().build();

  const input = '''
こんにちは **太字** と *斜体* のテキスト！
@user@example.com がメンションしました
#misskey をチェック
https://misskey.io にアクセス
:custom_emoji: と 😇
\$[shake 🍮]
> これは引用です
''';

  final result = parser.parse(input);

  if (result.isSuccess) {
    final nodes = result.value; // List<MfmNode>
    print('${nodes.length} 個のノードをパースしました');
    
    for (final node in nodes) {
      print('  - ${node.runtimeType}');
    }
  } else {
    print('パースエラー: ${result.message}');
  }
}
```

**出力：**

```
15 個のノードをパースしました
  - TextNode
  - BoldNode
  - TextNode
  - ItalicNode
  - TextNode
  - MentionNode
  - TextNode
  - HashtagNode
  - TextNode
  - UrlNode
  - TextNode
  - EmojiCodeNode
  - TextNode
  - UnicodeEmojiNode
  - TextNode
  - FnNode
  - TextNode
  - QuoteNode
```

---

## シンプルパーサー

シンプルパーサーは、以下のみを認識する軽量パーサーです：

- プレーンテキスト
- Unicode絵文字（例：`😇`、`🎉`）
- カスタム絵文字コード（例：`:wave:`、`:misskey:`）
- plainタグ（`<plain>...</plain>`）

その他のMFM構文（太字、斜体、メンション、ハッシュタグ、URLなど）はすべてプレーンテキストとして扱われます。

**ユースケース：**
- ユーザー名の表示
- 通知のプレビュー
- フルパースが不要なパフォーマンス重視の場面

```dart
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

void main() {
  final simpleParser = MfmParser().buildSimple();

  const input = 'こんにちは 😇 :wave: **太字ではない** @user #tag';

  final result = simpleParser.parse(input);

  if (result.isSuccess) {
    for (final node in result.value) {
      switch (node) {
        case TextNode(:final text):
          print('TextNode: "$text"');
        case UnicodeEmojiNode(:final emoji):
          print('UnicodeEmojiNode: $emoji');
        case EmojiCodeNode(:final name):
          print('EmojiCodeNode: :$name:');
        default:
          print('${node.runtimeType}');
      }
    }
  }
}
```

**出力：**

```
TextNode: "こんにちは "
UnicodeEmojiNode: 😇
TextNode: " "
EmojiCodeNode: :wave:
TextNode: " **太字ではない** @user #tag"
```

`**太字ではない**`、`@user`、`#tag` がプレーンテキストとして扱われます。

---

## ネスト制限のカスタマイズ

MFMではネスト構造（例：リンク内の斜体内の太字）が可能です。  
過度なネストによるパフォーマンス問題を防ぐため、ネスト制限を設定できます。（特別理由がなければmisskeyとの差異を防ぐ為にデフォルト値を使う事を推奨）

- **デフォルト値：** 20（mfm.jsと同じ）
- ネスト深度が制限に達すると、それ以降のネスト構文はプレーンテキストとして処理されます

```dart
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

void main() {
  // カスタムネスト制限でパーサーを作成
  final parser = MfmParser().build(nestLimit: 5);

  const input = '**太字 *斜体 ~~取り消し **さらに深く** 取り消し~~ 斜体* 太字**';
  
  final result = parser.parse(input);

  if (result.isSuccess) {
    printNodes(result.value);
  }
}

void printNodes(List<MfmNode> nodes, {int indent = 0}) {
  final prefix = '  ' * indent;
  for (final node in nodes) {
    switch (node) {
      case TextNode(:final text):
        print('$prefix TextNode: "$text"');
      case BoldNode(:final children):
        print('${prefix}BoldNode:');
        printNodes(children, indent: indent + 1);
      case ItalicNode(:final children):
        print('${prefix}ItalicNode:');
        printNodes(children, indent: indent + 1);
      case StrikeNode(:final children):
        print('${prefix}StrikeNode:');
        printNodes(children, indent: indent + 1);
      default:
        print('$prefix${node.runtimeType}');
    }
  }
}
```

---

## ノードタイプ別の処理

パースされたMFMをレンダリングまたは処理する際は、各ノードタイプを適切に処理する必要があります。以下は行う際の例です：

```dart
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';

void main() {
  final parser = MfmParser().build();
  
  const input = '''
**ようこそ** @alice@example.com さんの投稿へ！
#flutter をチェックして https://flutter.dev にアクセス
コード例: `print("Hello")`
\$[spin 🌟]
''';

  final result = parser.parse(input);

  if (result.isSuccess) {
    for (final node in result.value) {
      processNode(node);
    }
  }
}

void processNode(MfmNode node, {int indent = 0}) {
  final prefix = '  ' * indent;

  switch (node) {
    // リーフノード（子要素なし）
    case TextNode(:final text):
      print('${prefix}Text: "$text"');

    case UnicodeEmojiNode(:final emoji):
      print('${prefix}UnicodeEmoji: $emoji');

    case EmojiCodeNode(:final name):
      print('${prefix}CustomEmoji: :$name:');

    case MentionNode(:final username, :final host, :final acct):
      print('${prefix}Mention: @$acct (user=$username, host=$host)');

    case HashtagNode(:final hashtag):
      print('${prefix}Hashtag: #$hashtag');

    case UrlNode(:final url, :final brackets):
      print('${prefix}URL: $url (brackets=$brackets)');

    case InlineCodeNode(:final code):
      print('${prefix}InlineCode: `$code`');

    case CodeBlockNode(:final code, :final language):
      print('${prefix}CodeBlock (lang=${language ?? "none"}):');
      print('$prefix  $code');

    case MathInlineNode(:final formula):
      print('${prefix}MathInline: \\($formula\\)');

    case MathBlockNode(:final formula):
      print('${prefix}MathBlock: \\[$formula\\]');

    case SearchNode(:final query, :final content):
      print('${prefix}Search: query="$query", content="$content"');

    // コンテナノード（子要素あり）
    case BoldNode(:final children):
      print('${prefix}Bold:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case ItalicNode(:final children):
      print('${prefix}Italic:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case StrikeNode(:final children):
      print('${prefix}Strike:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case SmallNode(:final children):
      print('${prefix}Small:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case CenterNode(:final children):
      print('${prefix}Center:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case QuoteNode(:final children):
      print('${prefix}Quote:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case PlainNode(:final children):
      print('${prefix}Plain:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case LinkNode(:final url, :final silent, :final children):
      print('${prefix}Link (url=$url, silent=$silent):');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }

    case FnNode(:final name, :final args, :final children):
      print('${prefix}Function \$[$name${_formatArgs(args)}]:');
      for (final child in children) {
        processNode(child, indent: indent + 1);
      }
  }
}

String _formatArgs(Map<String, dynamic> args) {
  if (args.isEmpty) return '';
  
  final parts = args.entries.map((e) {
    if (e.value == true) return e.key;
    return '${e.key}=${e.value}';
  });
  
  return '.${parts.join(",")}';
}
```

---

## ノードタイプ一覧

| ノードタイプ | 子要素あり | 説明 |
|-------------|-----------|------|
| `TextNode` | なし | プレーンテキスト |
| `UnicodeEmojiNode` | なし | Unicode絵文字（例：😇） |
| `EmojiCodeNode` | なし | カスタム絵文字（例：:wave:） |
| `MentionNode` | なし | ユーザーメンション（@user または @user@host） |
| `HashtagNode` | なし | ハッシュタグ（#tag） |
| `UrlNode` | なし | URL（https://...） |
| `InlineCodeNode` | なし | インラインコード（\`code\`） |
| `CodeBlockNode` | なし | コードブロック（\`\`\`code\`\`\`） |
| `MathInlineNode` | なし | インライン数式（\\(formula\\)） |
| `MathBlockNode` | なし | ブロック数式（\\[formula\\]） |
| `SearchNode` | なし | 検索ブロック |
| `BoldNode` | あり | 太字（\*\*text\*\*） |
| `ItalicNode` | あり | 斜体（\*text\*） |
| `StrikeNode` | あり | 取り消し線（\~\~text\~\~） |
| `SmallNode` | あり | 小文字（\<small\>text\</small\>） |
| `CenterNode` | あり | 中央寄せ（\<center\>text\</center\>） |
| `QuoteNode` | あり | 引用ブロック（> text） |
| `PlainNode` | あり | プレーンブロック（\<plain\>text\</plain\>） |
| `LinkNode` | あり | リンク（\[label\](url)） |
| `FnNode` | あり | MFM関数（$[name content]） |
