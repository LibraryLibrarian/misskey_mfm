import 'dart:convert';

import 'package:misskey_mfm_parser/src/ast.dart';
import 'package:misskey_mfm_parser/src/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

import '../support/ast_json.dart';
import '../support/golden_fixture.dart';

void main() {
  final fixtures = loadAstGoldenFixtures();

  group('file-based MFM AST goldens', () {
    for (final fixture in fixtures) {
      test(fixture.name, () {
        final parser = switch (fixture.parserMode) {
          'full' => MfmParser().build(nestLimit: fixture.nestLimit),
          'simple' => MfmParser().buildSimple(),
          // The fixture validator rejects unknown modes before tests register.
          _ => throw StateError('Unknown parser mode: ${fixture.parserMode}'),
        };

        final result = parser.parse(fixture.input);
        if (result is! Success<List<MfmNode>>) {
          fail(
            'Golden case "${fixture.name}" from ${fixture.source} failed to '
            'parse:\n$result',
          );
        }
        expect(
          result.position,
          fixture.input.length,
          reason: 'Golden case "${fixture.name}" did not consume all input.',
        );

        final serialized = serializeMfmAst(result.value);
        final actual = _prettyCanonicalJson(serialized);
        expect(
          _prettyCanonicalJson(serializeMfmAst(result.value)),
          actual,
          reason:
              'Serializer output was not deterministic for golden case '
              '"${fixture.name}".',
        );
        final expected = _prettyCanonicalJson(fixture.expected);
        expect(
          actual,
          expected,
          reason:
              'AST mismatch for golden case "${fixture.name}" '
              'from ${fixture.source}.',
        );
      });
    }
  });
}

String _prettyCanonicalJson(Object? value) {
  return const JsonEncoder.withIndent('  ').convert(_canonicalJson(value));
}

Object? _canonicalJson(Object? value) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List<Object?>() => value.map(_canonicalJson).toList(growable: false),
    Map() => _canonicalMap(value),
    _ => throw ArgumentError.value(value, 'value', 'Not JSON-compatible'),
  };
}

Map<String, Object?> _canonicalMap(Map<Object?, Object?> value) {
  final entries = <MapEntry<String, Object?>>[];
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) {
      throw ArgumentError.value(key, 'key', 'JSON map keys must be strings');
    }
    entries.add(MapEntry(key, entry.value));
  }
  entries.sort((a, b) => a.key.compareTo(b.key));
  return <String, Object?>{
    for (final entry in entries) entry.key: _canonicalJson(entry.value),
  };
}
