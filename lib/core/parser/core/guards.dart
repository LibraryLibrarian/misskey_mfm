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

/// 行頭パーサー
///
/// 現在位置が行の先頭であることを検証する
/// - 入力の先頭（position == 0）
/// - 直前の文字が改行（\n または \r）
class LineBeginParser extends Parser<void> {
  @override
  Result<void> parseOn(Context context) {
    final position = context.position;
    if (position == 0) {
      return context.success(null);
    }
    final prevChar = context.buffer[position - 1];
    if (prevChar == '\n' || prevChar == '\r') {
      return context.success(null);
    }
    return context.failure('not at line begin');
  }

  @override
  int fastParseOn(String buffer, int position) {
    if (position == 0) {
      return position;
    }
    final prevChar = buffer[position - 1];
    if (prevChar == '\n' || prevChar == '\r') {
      return position;
    }
    return -1;
  }

  @override
  Parser<void> copy() => LineBeginParser();
}

Parser<void> lineBegin() => LineBeginParser();

/// 行末パーサー
///
/// 現在位置が行の末尾であることを検証する
/// - 入力の末尾（position >= buffer.length）
/// - 現在位置の文字が改行（\n または \r）
class LineEndParser extends Parser<void> {
  @override
  Result<void> parseOn(Context context) {
    final position = context.position;
    if (position >= context.buffer.length) {
      return context.success(null);
    }
    final currentChar = context.buffer[position];
    if (currentChar == '\n' || currentChar == '\r') {
      return context.success(null);
    }
    return context.failure('not at line end');
  }

  @override
  int fastParseOn(String buffer, int position) {
    if (position >= buffer.length) {
      return position;
    }
    final currentChar = buffer[position];
    if (currentChar == '\n' || currentChar == '\r') {
      return position;
    }
    return -1;
  }

  @override
  Parser<void> copy() => LineEndParser();
}

Parser<void> lineEnd() => LineEndParser();
