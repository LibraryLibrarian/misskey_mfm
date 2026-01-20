# mfm.js 互換テスト

このディレクトリには、mfm.jsプロジェクトのテストを Dart に移植したテストが含まれる

## ファイル構成

- `simple_parser_test.dart` - mfm.js/test/parser.ts の SimpleParser セクション（行8-66）
- `full_parser_test.dart` - mfm.js/test/parser.ts の FullParser セクション（行68-1540）

## 対応元

- リポジトリ: https://github.com/misskey-dev/mfm.js
- テストファイル: test/parser.ts

## 更新手順

1. mfm.js のテストファイル (test/parser.ts) を確認
2. 新しいテストケースを対応する group に追加
3. コメントで元の行番号を記載（例: `// mfm.js:123-130`）
4. テスト名に `mfm-js互換:` プレフィックスを付ける

## mfm.js テスト構造との対応表

| mfm.js 行番号 | セクション | Dart ファイル |
|--------------|-----------|--------------|
| 8-66 | SimpleParser | simple_parser_test.dart |
| 68-75 | text | full_parser_test.dart |
| 77-183 | quote | full_parser_test.dart |
| 185-239 | search | full_parser_test.dart |
| 241-284 | code block | full_parser_test.dart |
| 286-317 | mathBlock | full_parser_test.dart |
| 319-340 | center | full_parser_test.dart |
| 342-348 | emoji code | full_parser_test.dart |
| 350-362 | unicode emoji | full_parser_test.dart |
| 364-399 | big | full_parser_test.dart |
| 402-438 | bold tag | full_parser_test.dart |
| 440-476 | bold | full_parser_test.dart |
| 478-514 | small | full_parser_test.dart |
| 516-552 | italic tag | full_parser_test.dart |
| 554-592 | italic alt 1 | full_parser_test.dart |
| 594-632 | italic alt 2 | full_parser_test.dart |
| 634-642 | strike tag | full_parser_test.dart |
| 644-652 | strike | full_parser_test.dart |
| 654-672 | inlineCode | full_parser_test.dart |
| 674-680 | mathInline | full_parser_test.dart |
| 682-796 | mention | full_parser_test.dart |
| 798-928 | hashtag | full_parser_test.dart |
| 930-1064 | url | full_parser_test.dart |
| 1066-1228 | link | full_parser_test.dart |
| 1230-1280 | fn | full_parser_test.dart |
| 1282-1302 | plain | full_parser_test.dart |
| 1304-1509 | nesting limit | full_parser_test.dart |
| 1512-1540 | composite | full_parser_test.dart |
