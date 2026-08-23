import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../core/guards.dart';

/// 検索ブロックパーサー
///
/// 検索構文を解析する。行頭から始まり、行末で終わる。
///
/// mfm-js仕様:
/// - 形式: `query Search`、`query 検索`、`query [Search]`、`query [検索]`
/// - 大文字小文字は区別されない
/// - 行頭から始まり、行末で終わる
/// - クエリとボタンの間にはスペースが必要
class SearchParser {
  /// 検索ブロックパーサー
  Parser<MfmNode> build() {
    final lineBreak = newline();
    // スペース（半角・全角・タブ）
    final space = pattern(' \u3000\t');

    // 検索ボタン: [検索], [Search], 検索, Search（大文字小文字不問）
    final searchKeyword =
        string('検索', ignoreCase: true) | string('search', ignoreCase: true);
    final buttonBracket = seq3(
      char('['),
      searchKeyword,
      char(']'),
    ).flatten();
    final buttonNoBracket = searchKeyword.flatten();
    final button = buttonBracket | buttonNoBracket;

    // 行末判定
    final lineEnd = lineBreak.not() & endOfInput() | lineBreak;

    // クエリ部分: 改行またはスペース+ボタン+行末が出現するまでの文字列
    final queryChar =
        (lineBreak.not() &
                (space & button & (lineBreak | endOfInput())).not() &
                any())
            .pick(2);
    final query = queryChar.plus().flatten();

    // 先頭の改行を消費した直後が、実際の行頭であることを検証する
    final startPart = seq2(lineBreak.optional(), lineBegin());

    // seq5で型安全なシーケンスパース
    return seq5(
      startPart,
      query,
      space.flatten(),
      button,
      lineEnd.optional(),
    ).map5((start, queryStr, spaceStr, buttonStr, trailingLineEnd) {
      final content = '$queryStr$spaceStr$buttonStr';
      return SearchNode(query: queryStr, content: content);
    });
  }
}
