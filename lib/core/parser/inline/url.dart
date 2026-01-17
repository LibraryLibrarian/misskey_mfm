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
  Parser<MfmNode> build({NestState? state}) {
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
  Parser<MfmNode> buildWithFallback({NestState? state}) {
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
  _UrlParserImpl({this.state});

  /// 共有ネスト状態（nullの場合は独自のデフォルト制限を使用）
  final NestState? state;

  /// デフォルトのネスト深度制限（state未指定時）
  static const _defaultNestLimit = 20;

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

    // URL内容を解析（グローバルdepthから開始）
    final contentBuffer = StringBuffer();
    final initialDepth = state?.depth ?? 0;
    position = _parseUrlContent(buffer, position, contentBuffer, initialDepth);

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
  /// [depth] は現在のグローバルネスト深度を含む
  int _parseUrlContent(
    String buffer,
    int startPosition,
    StringBuffer output,
    int depth,
  ) {
    var currentPos = startPosition;

    // ネスト制限を取得（グローバル or デフォルト）
    final limit = state?.limit ?? _defaultNestLimit;

    while (currentPos < buffer.length) {
      final c = buffer[currentPos];

      // 開き括弧の場合
      if (c == '(' || c == '[') {
        final closing = c == '(' ? ')' : ']';

        // ネスト深度制限チェック（mfm-js互換: depth + 1 > limit）
        if (depth + 1 > limit) {
          break;
        }

        // 括弧内の内容を一時バッファに解析
        final innerBuffer = StringBuffer();
        final newPosition = _parseUrlContent(
          buffer,
          currentPos + 1,
          innerBuffer,
          depth + 1,
        );

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
