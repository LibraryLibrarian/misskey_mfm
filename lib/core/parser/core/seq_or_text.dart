import 'package:petitparser/petitparser.dart';

/// シーケンスまたはテキストとして扱う合成パーサー
///
/// mfm.js の `seqOrText` と同等の挙動を目指した合成関数。
/// 引数で与えた [start] → [inner] → [end] の順に解析を試み、
/// すべて成功した場合はシーケンス結果（`[start, innerList, end]`）を返す。
/// 途中で失敗した場合でも [start] までは消費できていたなら、
/// その位置から入力末尾までのテキストを文字列として成功扱いで返す。
///（つまり「部分一致はテキスト扱い」にフォールバックする）
Parser<dynamic> seqOrText(Parser start, Parser inner, Parser end) {
  // (end.not() & inner) の2要素シーケンスから inner の値だけを取り出す
  final Parser innerList = (end.not() & inner)
      .map((dynamic v) => (v as List)[1])
      .plus();

  // 正常系: start, innerList, end の順でマッチ
  final Parser sequence = (start & innerList & end);

  // フォールバック: start 以降をそのまま文字列として返す
  final Parser<String> fallback = (start & any().star()).flatten();

  return (sequence | fallback);
}
