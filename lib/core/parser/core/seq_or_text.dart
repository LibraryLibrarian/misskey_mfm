import 'package:petitparser/petitparser.dart';

/// seqOrTextの結果を表すsealed class
sealed class SeqOrTextResult<T> {
  const SeqOrTextResult();
}

/// 成功時: 内部コンテンツのリストを保持
final class SeqOrTextSuccess<T> extends SeqOrTextResult<T> {
  const SeqOrTextSuccess(this.children);

  final List<T> children;
}

/// フォールバック時: 開始マーカー以降のテキストを保持
final class SeqOrTextFallback<T> extends SeqOrTextResult<T> {
  const SeqOrTextFallback(this.text);

  final String text;
}

/// シーケンスまたはテキストとして扱う型安全な合成パーサー
///
/// mfm.js の `seqOrText` と同等の挙動を目指した合成関数。
/// 引数で与えた [start] → [inner] → [end] の順に解析を試み、
/// すべて成功した場合は [SeqOrTextSuccess] を返す
/// 途中で失敗した場合でも [start] までは消費できていたなら、
/// その位置から入力末尾までのテキストを [SeqOrTextFallback] として成功扱いで返す
///（つまり「部分一致はテキスト扱い」にフォールバックする）
Parser<SeqOrTextResult<T>> seqOrText<T>(
  Parser<String> start,
  Parser<T> inner,
  Parser<String> end,
) {
  // (end.not() & inner) の2要素シーケンスから inner の値だけを取り出す
  final innerList = seq2(end.not(), inner).map((r) => r.$2).plus();

  // 正常系: start, innerList, end の順でマッチ → SeqOrTextSuccess
  final sequence = seq3(start, innerList, end).map<SeqOrTextResult<T>>(
    (r) => SeqOrTextSuccess<T>(r.$2),
  );

  // フォールバック: start 以降をそのまま文字列として返す → SeqOrTextFallback
  final fallback = seq2(
    start,
    any().star(),
  ).flatten().map<SeqOrTextResult<T>>(SeqOrTextFallback<T>.new);

  return (sequence | fallback).cast<SeqOrTextResult<T>>();
}
