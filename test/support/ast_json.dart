import 'package:misskey_mfm_parser/src/ast.dart';

/// Converts an MFM AST to the stable JSON shape used by golden fixtures.
///
/// This intentionally lives under `test/` so the compatibility-test format
/// does not become part of the package's public API. The exhaustive switch
/// makes a newly added [MfmNode] variant a compile-time error until its golden
/// representation is defined.
List<Map<String, Object?>> serializeMfmAst(List<MfmNode> nodes) {
  return nodes.map(serializeMfmNode).toList(growable: false);
}

/// Converts one MFM node to a deterministic JSON object.
Map<String, Object?> serializeMfmNode(MfmNode node) {
  final record = switch (node) {
    TextNode(:final text) => (
      type: 'text',
      props: <String, Object?>{'text': text},
      children: const <MfmNode>[],
    ),
    InlineCodeNode(:final code) => (
      type: 'inlineCode',
      props: <String, Object?>{'code': code},
      children: const <MfmNode>[],
    ),
    EmojiCodeNode(:final name) => (
      type: 'emojiCode',
      props: <String, Object?>{'name': name},
      children: const <MfmNode>[],
    ),
    UnicodeEmojiNode(:final emoji) => (
      type: 'unicodeEmoji',
      props: <String, Object?>{'emoji': emoji},
      children: const <MfmNode>[],
    ),
    HashtagNode(:final hashtag) => (
      type: 'hashtag',
      props: <String, Object?>{'hashtag': hashtag},
      children: const <MfmNode>[],
    ),
    MathBlockNode(:final formula) => (
      type: 'mathBlock',
      props: <String, Object?>{'formula': formula},
      children: const <MfmNode>[],
    ),
    MathInlineNode(:final formula) => (
      type: 'mathInline',
      props: <String, Object?>{'formula': formula},
      children: const <MfmNode>[],
    ),
    BoldNode(:final children) => (
      type: 'bold',
      props: const <String, Object?>{},
      children: children,
    ),
    ItalicNode(:final children) => (
      type: 'italic',
      props: const <String, Object?>{},
      children: children,
    ),
    StrikeNode(:final children) => (
      type: 'strike',
      props: const <String, Object?>{},
      children: children,
    ),
    SmallNode(:final children) => (
      type: 'small',
      props: const <String, Object?>{},
      children: children,
    ),
    QuoteNode(:final children) => (
      type: 'quote',
      props: const <String, Object?>{},
      children: children,
    ),
    CenterNode(:final children) => (
      type: 'center',
      props: const <String, Object?>{},
      children: children,
    ),
    PlainNode(:final children) => (
      type: 'plain',
      props: const <String, Object?>{},
      children: children,
    ),
    UrlNode(:final url, :final brackets) => (
      type: 'url',
      props: <String, Object?>{'url': url, 'brackets': brackets},
      children: const <MfmNode>[],
    ),
    LinkNode(:final silent, :final url, :final children) => (
      type: 'link',
      props: <String, Object?>{'silent': silent, 'url': url},
      children: children,
    ),
    MentionNode(:final username, :final host, :final acct) => (
      type: 'mention',
      props: <String, Object?>{
        'username': username,
        'host': host,
        'acct': acct,
      },
      children: const <MfmNode>[],
    ),
    FnNode(:final name, :final args, :final children) => (
      type: 'fn',
      props: <String, Object?>{'name': name, 'args': args},
      children: children,
    ),
    CodeBlockNode(:final code, :final language) => (
      type: 'codeBlock',
      props: <String, Object?>{'code': code, 'language': language},
      children: const <MfmNode>[],
    ),
    SearchNode(:final query, :final content) => (
      type: 'search',
      props: <String, Object?>{'query': query, 'content': content},
      children: const <MfmNode>[],
    ),
  };

  return <String, Object?>{
    'type': record.type,
    'props': _normalizeJsonMap(record.props),
    'children': serializeMfmAst(record.children),
  };
}

Map<String, Object?> _normalizeJsonMap(Map<String, Object?> value) {
  final keys = value.keys.toList(growable: false)..sort();
  return <String, Object?>{
    for (final key in keys) key: _normalizeJsonValue(value[key]),
  };
}

Object? _normalizeJsonValue(Object? value) {
  return switch (value) {
    null || bool() || String() => value,
    final num number when number.isFinite => number,
    num() => throw ArgumentError.value(
      value,
      'value',
      'AST golden numbers must be finite JSON values',
    ),
    List<Object?>() => value.map(_normalizeJsonValue).toList(growable: false),
    Map<String, Object?>() => _normalizeJsonMap(value),
    _ => throw ArgumentError.value(
      value,
      'value',
      'AST golden properties must be JSON-compatible',
    ),
  };
}
