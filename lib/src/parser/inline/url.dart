import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../core/nest.dart';

/// URLパーサー
///
/// mfm-js仕様に準拠したURL自動リンクを解析
///
/// **url**: `https?://` で始まる生URL
/// - 使用可能文字: `[.,a-z0-9_/:%#@$&?!~=+-]`
/// - 括弧 `()` と `[]` はネスト構造としてペアで処理
/// - 末尾の `.` や `,` は除去
///
/// **urlAlt**: `<https://...>` 形式（brackets=true）
/// - スペースと改行以外の文字を使用可
class UrlParser {
  /// 末尾の無効文字パターン（. や ,）
  static final _trailingInvalidPattern = RegExp(r'[.,]+$');

  /// URL用の通常文字パターン
  static final _urlCharPattern = RegExp(r'[.,a-zA-Z0-9_/:%#@$&?!~=+-]');

  /// 生URLパーサーを構築
  ///
  /// `https://example.com` 形式のURLを解析
  /// [state] ネスト状態（グローバルな深度制限を共有、必須）
  Parser<MfmNode> build({required NestState state}) {
    return _UrlParserImpl(state: state);
  }

  /// ブラケット付きURLパーサーを構築
  ///
  /// `<https://example.com>` 形式のURLを解析
  Parser<MfmNode> buildAlt() {
    return _UrlAltParserImpl();
  }

  /// フォールバック付き生URLパーサー
  ///
  /// URLとして解析できない場合は、スキーマ部分をテキストとして扱う
  /// [state] ネスト状態（グローバルな深度制限を共有、必須）
  Parser<MfmNode> buildWithFallback({required NestState state}) {
    final completeUrl = build(state: state);

    // フォールバック: `http` で始まるがURLとして解析できない場合
    final fallback = (string('https://') | string('http://')).flatten().map(
      (dynamic s) => TextNode(s as String),
    );

    return (completeUrl | fallback).cast<MfmNode>();
  }

  /// 末尾の無効文字を除去
  static String trimTrailingInvalid(String s) {
    return s.replaceFirst(_trailingInvalidPattern, '');
  }

  /// URL用の通常文字かどうか
  static bool isUrlChar(String c) => _urlCharPattern.hasMatch(c);
}

/// 生URLパーサーの実装
///
/// 括弧のネスト構造をサポートし、末尾の無効文字を除去する
class _UrlParserImpl extends Parser<MfmNode> {
  _UrlParserImpl({required this.state});

  /// 共有ネスト状態（グローバルな深度制限を共有）
  final NestState state;

  @override
  Result<MfmNode> parseOn(Context context) {
    final buffer = context.buffer;
    var position = context.position;

    // スキーマをチェック（https:// または http://）
    String? schema;
    if (buffer.substring(position).startsWith('https://')) {
      schema = 'https://';
      position += 8;
    } else if (buffer.substring(position).startsWith('http://')) {
      schema = 'http://';
      position += 7;
    } else {
      return context.failure('expected http:// or https://');
    }

    // URL内容を解析
    final contentBuffer = StringBuffer();
    position = _parseUrlContent(buffer, position, contentBuffer);

    var content = contentBuffer.toString();

    // 内容が空の場合は無効
    if (content.isEmpty) {
      return context.failure('empty URL content');
    }

    // 末尾の `.` や `,` を除去
    final originalLength = content.length;
    content = UrlParser.trimTrailingInvalid(content);
    final trimmedCount = originalLength - content.length;

    // 除去した分だけ位置を戻す
    position -= trimmedCount;

    // 内容が空になった場合は無効
    if (content.isEmpty) {
      return context.failure('URL content is only trailing chars');
    }

    final url = schema + content;
    return context.success(UrlNode(url: url), position);
  }

  /// URL内容を再帰的に解析
  ///
  /// mfm-js互換: 括弧に入る際にグローバルな state.depth を直接変更
  /// ネスト制限に達した場合、括弧内は文字単位でマッチ（フォールバック）
  ///
  /// [buffer] 入力文字列
  /// [startPosition] 開始位置
  /// [output] 出力バッファ
  /// 戻り値: 新しい位置
  int _parseUrlContent(
    String buffer,
    int startPosition,
    StringBuffer output,
  ) {
    var currentPos = startPosition;

    // ネスト制限を取得
    final limit = state.limit!;

    while (currentPos < buffer.length) {
      final c = buffer[currentPos];

      // 開き括弧の場合
      if (c == '(' || c == '[') {
        final closing = c == '(' ? ')' : ']';

        // mfm-js互換: グローバル深度をインクリメント
        state.depth++;

        // ネスト深度制限チェック（mfm-js互換: depth >= limit でフォールバック）
        final useFallback = state.depth >= limit;

        // 括弧内の内容を一時バッファに解析
        final innerBuffer = StringBuffer();
        final int newPosition;

        if (useFallback) {
          // フォールバック: 文字単位でマッチ（括弧で停止）
          newPosition = _parseUrlContentFallback(
            buffer,
            currentPos + 1,
            innerBuffer,
          );
        } else {
          // 通常: 再帰的にパース
          newPosition = _parseUrlContent(
            buffer,
            currentPos + 1,
            innerBuffer,
          );
        }

        // mfm-js互換: グローバル深度をデクリメント
        state.depth--;

        // 閉じ括弧があるかチェック
        if (newPosition < buffer.length && buffer[newPosition] == closing) {
          // 括弧ペアが完成 - URLに含める
          output
            ..write(c)
            ..write(innerBuffer)
            ..write(closing);
          currentPos = newPosition + 1;
        } else {
          // 閉じ括弧がない場合は開き括弧で終了
          break;
        }
      } else if (c == ')' || c == ']') {
        // 閉じ括弧は呼び出し元で処理するため、ここで終了
        break;
      } else if (UrlParser.isUrlChar(c)) {
        // 通常のURL文字
        output.write(c);
        currentPos++;
      } else {
        // URL文字以外で終了
        break;
      }
    }

    return currentPos;
  }

  /// フォールバック用のURL内容解析（文字単位マッチ）
  ///
  /// mfm-js互換: nest()のfallback=urlCharに相当
  /// URL文字のみマッチし、括弧類で停止する
  int _parseUrlContentFallback(
    String buffer,
    int startPosition,
    StringBuffer output,
  ) {
    var currentPos = startPosition;

    while (currentPos < buffer.length) {
      final c = buffer[currentPos];

      // 括弧類なら終了（フォールバックでは括弧をマッチしない）
      if (c == '(' || c == '[' || c == ')' || c == ']') {
        break;
      }

      // URL文字ならマッチ
      if (UrlParser.isUrlChar(c)) {
        output.write(c);
        currentPos++;
      } else {
        // URL文字以外で終了
        break;
      }
    }

    return currentPos;
  }

  @override
  int fastParseOn(String buffer, int position) {
    final result = parseOn(Context(buffer, position));
    return result is Success ? result.position : -1;
  }

  @override
  Parser<MfmNode> copy() => _UrlParserImpl(state: state);
}

/// ブラケット付きURLパーサーの実装
///
/// `<https://example.com>` 形式のURLを解析
class _UrlAltParserImpl extends Parser<MfmNode> {
  @override
  Result<MfmNode> parseOn(Context context) {
    final buffer = context.buffer;
    var position = context.position;

    // `<` で始まることを確認
    if (position >= buffer.length || buffer[position] != '<') {
      return context.failure('expected <');
    }
    position++;

    // スキーマをチェック（https:// または http://）
    String? schema;
    if (buffer.substring(position).startsWith('https://')) {
      schema = 'https://';
      position += 8;
    } else if (buffer.substring(position).startsWith('http://')) {
      schema = 'http://';
      position += 7;
    } else {
      return context.failure('expected http:// or https://');
    }

    // `>` または スペース/改行まで読み込む
    final contentBuffer = StringBuffer();
    while (position < buffer.length) {
      final c = buffer[position];
      if (c == '>') {
        break;
      }
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
        // スペースや改行があった場合は無効
        return context.failure('space or newline in bracketed URL');
      }
      contentBuffer.write(c);
      position++;
    }

    // `>` で終わることを確認
    if (position >= buffer.length || buffer[position] != '>') {
      return context.failure('expected >');
    }
    position++;

    final content = contentBuffer.toString();

    // 内容が空の場合は無効
    if (content.isEmpty) {
      return context.failure('empty URL content');
    }

    final url = schema + content;
    return context.success(UrlNode(url: url, brackets: true), position);
  }

  @override
  int fastParseOn(String buffer, int position) {
    final result = parseOn(Context(buffer, position));
    return result is Success ? result.position : -1;
  }

  @override
  Parser<MfmNode> copy() => _UrlAltParserImpl();
}
