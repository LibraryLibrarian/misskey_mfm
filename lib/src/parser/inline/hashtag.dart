import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../core/guards.dart';
import '../core/nest.dart';

/// ハッシュタグパーサー
///
/// `#tag` 形式のハッシュタグを解析
/// mfm-js仕様:
/// - 直前文字が `[a-zA-Z0-9]` に一致しない場合のみ有効
/// - 禁止文字: 半角スペース, 全角スペース(\u3000), タブ, 改行,
///   `. , ! ? ' " # : / 【 】 < >`
/// - 括弧類 `() [] 「」（）` はペアで現れる場合のみハッシュタグに含める
/// - ネスト深度制限はグローバルなnestLimit（デフォルト20）を使用
/// - 数字のみのタグは無効
/// - 禁止文字に当たるとそこでマッチ終了（残りはテキストとして扱われる）
class HashtagParser {
  /// 英数字パターン（直前文字チェック用）
  static final _alphanumericPattern = RegExp(r'[a-zA-Z0-9]');

  /// 禁止文字パターン（mfm-js準拠）
  ///
  /// mfm-js禁止文字:
  ///   半角スペース, 全角スペース(\u3000), タブ, 改行,
  ///   . , ! ? ' " # : / 【 】 < >
  ///
  /// 注意:
  /// - 括弧類 () [] 「」（） はペアリング処理で個別に扱う
  /// - _ はハッシュタグ名として有効なので禁止文字には含めない
  static final _forbiddenPattern = RegExp(r'[ \u3000\t\n.,!?\x27"#:/【】<>]');

  /// 括弧開始文字パターン
  static final _bracketOpenPattern = RegExp(r'[(\[「（]');

  /// 数字のみパターン
  static final _numericOnlyPattern = RegExp(r'^[0-9]+$');

  /// ハッシュタグパーサーを構築
  ///
  /// [state] ネスト状態（グローバルな深度制限を共有）
  /// mfm-js互換: ハッシュタグ内の括弧ネストもグローバルなnestLimitを使用
  Parser<MfmNode> build({required NestState state}) {
    // カスタムパーサーを使用して括弧ネスト構造をサポート
    final hashtagParser = _HashtagWithBracketsParser(state: state);

    // 直前文字ガードを適用
    return withPrevCharGuard<MfmNode>(
      hashtagParser,
      (prev) => prev == null || !_alphanumericPattern.hasMatch(prev),
    );
  }

  /// フォールバック付きパーサー
  ///
  /// ハッシュタグとして解析できない場合は、先頭の `#` をテキストとして扱う
  /// [state] ネスト状態（グローバルな深度制限を共有）
  Parser<MfmNode> buildWithFallback({required NestState state}) {
    final completeHashtag = build(state: state);

    // フォールバック: `#` で始まるがハッシュタグとして解析できない場合
    final fallback = char('#').map<MfmNode>(
      (dynamic c) => TextNode(c as String),
    );

    return (completeHashtag | fallback).cast<MfmNode>();
  }

  /// 禁止文字かどうかをチェック
  static bool isForbidden(String c) => _forbiddenPattern.hasMatch(c);

  /// 括弧開始文字かどうかをチェック
  static bool isBracketOpen(String c) => _bracketOpenPattern.hasMatch(c);

  /// 対応する閉じ括弧を取得
  static String? getClosingBracket(String open) {
    switch (open) {
      case '(':
        return ')';
      case '[':
        return ']';
      case '「':
        return '」';
      case '（':
        return '）';
      default:
        return null;
    }
  }

  /// 数字のみかどうかをチェック
  static bool isNumericOnly(String s) => _numericOnlyPattern.hasMatch(s);
}

/// 括弧ネスト構造をサポートするハッシュタグパーサー
class _HashtagWithBracketsParser extends Parser<MfmNode> {
  _HashtagWithBracketsParser({required this.state});

  /// 共有ネスト状態（グローバルな深度制限を共有）
  final NestState state;

  @override
  Result<MfmNode> parseOn(Context context) {
    final buffer = context.buffer;
    var position = context.position;

    // '#' で始まることを確認
    if (position >= buffer.length || buffer[position] != '#') {
      return context.failure('expected #');
    }
    position++;

    // タグ内容を解析
    final tagBuffer = StringBuffer();
    position = _parseTagContent(buffer, position, tagBuffer);

    final tag = tagBuffer.toString();

    // 空のタグは無効
    if (tag.isEmpty) {
      return context.failure('empty hashtag');
    }

    // 数字のみのタグは無効
    if (HashtagParser.isNumericOnly(tag)) {
      return context.failure('numeric only hashtag');
    }

    return context.success(HashtagNode(tag), position);
  }

  /// タグ内容を再帰的に解析
  ///
  /// mfm-js互換: 括弧に入る際にグローバルな state.depth を直接変更
  /// ネスト制限に達した場合、括弧内は文字単位でマッチ（フォールバック）
  ///
  /// [buffer] 入力文字列
  /// [startPosition] 開始位置
  /// [output] 出力バッファ
  /// 戻り値: 新しい位置
  int _parseTagContent(
    String buffer,
    int startPosition,
    StringBuffer output,
  ) {
    var currentPos = startPosition;

    // ネスト制限を取得
    final limit = state.limit!;

    while (currentPos < buffer.length) {
      final c = buffer[currentPos];

      // 禁止文字なら終了
      if (HashtagParser.isForbidden(c)) {
        break;
      }

      // 括弧開始文字の場合
      if (HashtagParser.isBracketOpen(c)) {
        final closing = HashtagParser.getClosingBracket(c)!;

        // mfm-js互換: グローバル深度をインクリメント
        state.depth++;

        // ネスト深度制限チェック（mfm-js互換: depth >= limit でフォールバック）
        final useFallback = state.depth >= limit;

        // 括弧内の内容を一時バッファに解析
        final innerBuffer = StringBuffer();
        final int newPosition;

        if (useFallback) {
          // フォールバック: 文字単位でマッチ（禁止文字と括弧で停止）
          newPosition = _parseTagContentFallback(
            buffer,
            currentPos + 1,
            innerBuffer,
          );
        } else {
          // 通常: 再帰的にパース
          newPosition = _parseTagContent(
            buffer,
            currentPos + 1,
            innerBuffer,
          );
        }

        // mfm-js互換: グローバル深度をデクリメント
        state.depth--;

        // 閉じ括弧があるかチェック
        if (newPosition < buffer.length && buffer[newPosition] == closing) {
          // 括弧ペアが完成 - ハッシュタグに含める
          output
            ..write(c)
            ..write(innerBuffer)
            ..write(closing);
          currentPos = newPosition + 1;
        } else {
          // 閉じ括弧がない場合は開き括弧で終了
          break;
        }
      } else if (_isClosingBracket(c)) {
        // 閉じ括弧は呼び出し元で処理するため、ここで終了
        break;
      } else {
        // 通常の文字
        output.write(c);
        currentPos++;
      }
    }

    return currentPos;
  }

  /// フォールバック用のタグ内容解析（文字単位マッチ）
  ///
  /// mfm-js互換: nest()のfallback=hashTagCharに相当
  /// 禁止文字と括弧類で停止する
  int _parseTagContentFallback(
    String buffer,
    int startPosition,
    StringBuffer output,
  ) {
    var currentPos = startPosition;

    while (currentPos < buffer.length) {
      final c = buffer[currentPos];

      // 禁止文字なら終了
      if (HashtagParser.isForbidden(c)) {
        break;
      }

      // 括弧類なら終了（フォールバックでは括弧をマッチしない）
      if (HashtagParser.isBracketOpen(c) || _isClosingBracket(c)) {
        break;
      }

      // 通常の文字
      output.write(c);
      currentPos++;
    }

    return currentPos;
  }

  /// 閉じ括弧かどうかをチェック
  bool _isClosingBracket(String c) {
    return c == ')' || c == ']' || c == '」' || c == '）';
  }

  @override
  int fastParseOn(String buffer, int position) {
    // 簡易実装: parseOnを呼び出して結果を返す
    final result = parseOn(Context(buffer, position));
    return result is Success ? result.position : -1;
  }

  @override
  Parser<MfmNode> copy() => _HashtagWithBracketsParser(state: state);
}
