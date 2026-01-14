import 'package:petitparser/petitparser.dart';

/// 直前文字ガード付きパーサー
///
/// 対象位置の直前の1文字を判定し、許可された場合のみ [delegate]
/// を実行して結果を返す
class PrevCharGuardParser<R> extends Parser<R> {
  PrevCharGuardParser(this.delegate, this.allow);

  /// 委譲先のパーサー
  final Parser<R> delegate;

  /// 直前文字を許可するかどうかの述語
  /// null は入力先頭（直前文字なし）を表す
  final bool Function(String? prevChar) allow;

  @override
  Result<R> parseOn(Context context) {
    final buffer = context.buffer;
    final index = context.position;
    final prev = index == 0 ? null : buffer.substring(index - 1, index);
    if (!allow(prev)) {
      return context.failure('prev char not allowed');
    }
    return delegate.parseOn(context);
  }

  @override
  int fastParseOn(String buffer, int position) {
    final prev = position == 0
        ? null
        : buffer.substring(position - 1, position);
    if (!allow(prev)) return -1;
    return delegate.fastParseOn(buffer, position);
  }

  @override
  Parser<R> copy() => PrevCharGuardParser<R>(delegate, allow);
}

/// 直前文字ガードを付与するユーティリティ
Parser<T> withPrevCharGuard<T>(
  Parser<T> parser,
  bool Function(String? prev) allow,
) {
  return PrevCharGuardParser<T>(parser, allow);
}
