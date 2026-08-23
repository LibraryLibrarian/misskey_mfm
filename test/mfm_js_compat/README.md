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

## ASTゴールデンテスト

`test/goldens/mfm_ast_v1.json` は、パーサー結果を決定的なJSONへ正規化して
比較するファイルベースのASTゴールデンです。個別テストだけでは見落としやすい
ノード型、nullable/defaultプロパティ、ネスト、改行、Unicode、過去Issueの
代表回帰を、レビュー可能な固定fixtureとして保持します。

- schema version: `1`
- 互換基準: mfm.js `develop`
  (`61c9dd10d29a054489a346629b0bb420659aa626`)
- 原則は上記mfm.js基準。承認済みproject semanticsとの差はcase-levelの
  `deviation`（Issue番号と理由）を必須とし、未承認の例外はschemaで拒否
- parser mode: `full` または `simple`
- test-only serializer: `test/support/ast_json.dart`

固定commitのmfm.js buildとの実測では26件中25件が一致します。例外はIssue #3
`issue-3-second-line-inline-wins-over-search`の1件で、本projectでは後続行頭の
inline構文をSearchより優先するレビュー済みsemanticsを維持します。このcaseの
期待ASTをmfm.jsへ合わせて変更せず、`deviation`に出典と理由を記録しています。

fixtureは通常のテスト実行では更新されません。変更が必要な場合は次の手順で
手動レビューしてください。

1. mfm.jsの基準commit、既存の厳密ASTテスト、関連Issueの期待値を確認する
2. `input`、必要なら`nestLimit`、`expected`を手で更新する
3. 意図しない大量差分や、現在の実装結果をそのまま正解化していないか確認する
4. `dart test test/golden`を実行し、case名付きの差分を確認する
5. `dart format --output=none --set-exit-if-changed .`、`dart analyze`、
   `dart test`をすべて通す

新しい`MfmNode` variantを追加するとserializerのexhaustive switchがコンパイル
エラーになるため、JSON表現、serializer単体テスト、fixtureを同時に更新します。

GitHub Actionsはpull request、`develop`へのpush、手動実行で、最低対応SDK
`3.8.0`とstableの両方について依存解決、format check、analyze、goldenを含む
全testを実行します。

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
