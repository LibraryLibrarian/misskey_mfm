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

/// フォールバック時: 開始位置から最後に成功した位置までのテキストを保持
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
/// 最後に成功した位置までのテキストを [SeqOrTextFallback] として成功扱いで返す
///（つまり「部分一致はテキスト扱い」にフォールバックする）
Parser<SeqOrTextResult<T>> seqOrText<T>(
  Parser<String> start,
  Parser<T> inner,
  Parser<String> end,
) {
  // (end.not() & inner) の2要素シーケンスから inner の値だけを取り出す
  final innerList = seq2(end.not(), inner).map((r) => r.$2).plus();
  return _SeqOrTextParser<T>(start, innerList, end);
}

/// 子パーサーが最後に成功した位置を保持する `seqOrText` の実装。
///
/// PetitParser の通常の sequence は失敗位置を返すため、失敗した子パーサー
/// より前に確定していた消費位置をフォールバックに利用できない。mfm.js と同様に
/// 各子パーサーを順番に実行し、直前の成功位置までだけをテキストとして返す。
final class _SeqOrTextParser<T> extends Parser<SeqOrTextResult<T>> {
  _SeqOrTextParser(this.start, this.inner, this.end);

  Parser<String> start;
  Parser<List<T>> inner;
  Parser<String> end;

  @override
  Result<SeqOrTextResult<T>> parseOn(Context context) {
    final startResult = start.parseOn(context);
    if (startResult is Failure) return startResult;

    final innerResult = inner.parseOn(startResult);
    if (innerResult is Failure) {
      return _fallback(context, startResult.position, innerResult);
    }

    final endResult = end.parseOn(innerResult);
    if (endResult is Failure) {
      return _fallback(context, innerResult.position, endResult);
    }

    return endResult.success(SeqOrTextSuccess<T>(innerResult.value));
  }

  Result<SeqOrTextResult<T>> _fallback(
    Context context,
    int latestPosition,
    Failure failure,
  ) {
    // mfm.js は開始位置から何も消費できていない場合、元の失敗を返す。
    if (latestPosition == context.position) return failure;

    final text = context.buffer.substring(context.position, latestPosition);
    return context.success(
      SeqOrTextFallback<T>(text),
      latestPosition,
    );
  }

  @override
  List<Parser> get children => [start, inner, end];

  @override
  void replace(Parser source, Parser target) {
    super.replace(source, target);
    if (start == source) start = target as Parser<String>;
    if (inner == source) inner = target as Parser<List<T>>;
    if (end == source) end = target as Parser<String>;
  }

  @override
  Parser<SeqOrTextResult<T>> copy() => _SeqOrTextParser<T>(start, inner, end);
}
