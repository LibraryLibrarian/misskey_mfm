# MFM Parser 設計方針

## 概要
MFM（Markup language For Misskey）パーサーのDart処理は構文毎の分離した処理を採用してます。  
理由はMFM本体に対して個別の修正や新たなMFM構文が追加された場合でも対応が容易になる事を見込んで。

## ディレクトリ構造（一例）
```
lib/core/parser/
├── README.md              # このファイル
├── parser.dart            # メインパーサー（統合）
├── inline/                # インライン構文パーサー
│   ├── bold.dart          # 太字パーサー
│   ├── italic.dart        # 斜体パーサー
│   ├── strike.dart        # 取り消し線パーサー
│   ├── link.dart          # リンクパーサー
│   ├── mention.dart       # メンションパーサー
│   ├── hashtag.dart       # ハッシュタグパーサー
│   └── emoji.dart         # 絵文字パーサー
├── block/                 # ブロック構文パーサー
│   ├── quote.dart         # 引用パーサー
│   ├── code_block.dart    # コードブロックパーサー
│   └── math_block.dart    # 数式ブロックパーサー
└── common/                # 共通ユーティリティ
    ├── text.dart          # テキスト処理
    └── utils.dart         # 共通ユーティリティ
```

## 設計原則

### 1. モジュール化
- 各構文タイプごとに独立したパーサーファイルを作成
- 処理の分離により保守性を向上
- 新しい構文の追加が容易（さっきも書いたけどね、大事だから）

### 2. 統合パーサー
- `parser.dart`は各モジュールパーサーを統合する役割（じゃないと個別インポートでとんでもないことになる）
- 優先順位の管理と全体の制御を担当
- 単一のエントリーポイントを提供

### 3. 共通処理の抽出
- テキスト処理やユーティリティ関数は共通モジュールに配置
- 重複コードを削減

## 使用方法

### 基本的な使用方法
```dart
// メインパーサーを使用
final parser = MfmParser().build();
final result = parser.parse('**bold** *italic* text');
```

### 個別パーサーを使用（テストや特殊用途）
```dart
// 太字パーサーのみを使用
final boldParser = BoldParser().build();
final boldResult = boldParser.parse('**bold**');

// 斜体パーサーのみを使用
final italicParser = ItalicParser().build();
final italicResult = italicParser.parse('*italic*');
```

### テストでの使用
```dart
// 特定の構文のみをテスト
test('太字パーサーのテスト', () {
  final boldParser = BoldParser().buildWithFallback();
  final result = boldParser.parse('**test**');
  // テスト処理
});
```

## 優先順位
1. ブロック構文（引用、コードブロックなど）
2. インライン構文（太字、斜体、リンクなど）
3. テキスト

この順序で解析することで、適切なネスト構造を構築する想定ではあるが、  
まだ本家mfm.jsの解析が完了していないのでネスト構造に不備がある可能性は要考慮必要

## 拡張方法

### 新しいインライン構文の追加
1. `inline/`ディレクトリに新しいパーサーファイルを作成
2. 既存のパーサーを参考に実装
3. `parser.dart`の`_inlines()`メソッドに追加
4. テストケースを作成

例：
```dart
// inline/strike.dart
class StrikeParser {
  Parser<MfmNode> build() {
    // 取り消し線の実装
  }
  
  Parser<MfmNode> buildWithFallback() {
    // フォールバック処理
  }
}
```

### 新しいブロック構文の追加
1. `block/`ディレクトリに新しいパーサーファイルを作成
2. ブロックレベルの解析を実装
3. メインパーサーに統合
