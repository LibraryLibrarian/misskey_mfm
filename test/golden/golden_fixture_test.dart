import 'package:test/test.dart';

import '../support/golden_fixture.dart';

void main() {
  group('AST golden fixture schema', () {
    test('version管理fixtureを全件validateしてcase名を一意にする', () {
      final fixtures = loadAstGoldenFixtures();
      expect(fixtures, isNotEmpty);
      expect(
        fixtures.map((fixture) => fixture.name).toSet(),
        hasLength(fixtures.length),
      );
    });

    test('未知のparser modeを拒否する', () {
      final fixture = _validFixture();
      final cases = fixture['cases']! as List<Object?>;
      (cases.single! as Map<String, Object?>)['parser'] = 'unknown';

      expect(
        () => parseAstGoldenFixture(fixture),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('must be "full" or "simple"'),
          ),
        ),
      );
    });

    test('重複するcase名をfixture間でも拒否する', () {
      final names = <String>{};
      parseAstGoldenFixture(_validFixture(), knownNames: names);

      expect(
        () => parseAstGoldenFixture(_validFixture(), knownNames: names),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('duplicate golden case name'),
          ),
        ),
      );
    });

    for (final invalidVersion in <Object?>[1.0, '1', null, 2]) {
      test('intのschemaVersion 1以外 `$invalidVersion` を拒否する', () {
        final fixture = _validFixture()..['schemaVersion'] = invalidVersion;
        expect(
          () => parseAstGoldenFixture(fixture),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('simple parserのnestLimitを拒否する', () {
      final invalidSimple = _validFixture();
      _onlyCase(invalidSimple)
        ..['parser'] = 'simple'
        ..['nestLimit'] = 1;
      expect(
        () => parseAstGoldenFixture(invalidSimple),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('only valid for the full parser'),
          ),
        ),
      );
    });

    test('承認済みIssue #3 deviationのprovenanceを保持する', () {
      final fixture = _validFixture();
      _onlyCase(fixture)
        ..['name'] = 'issue-3-second-line-inline-wins-over-search'
        ..['deviation'] = <String, Object?>{
          'issue': 3,
          'rationale': 'Project-approved search priority.',
        };

      final parsed = parseAstGoldenFixture(fixture).single;
      expect(parsed.deviation?.issue, 3);
      expect(parsed.deviation?.rationale, isNotEmpty);
    });

    test('承認済みcaseでdeviation provenance欠落を拒否する', () {
      final fixture = _validFixture();
      _onlyCase(fixture)['name'] =
          'issue-3-second-line-inline-wins-over-search';

      expect(
        () => parseAstGoldenFixture(fixture),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('requires deviation provenance'),
          ),
        ),
      );
    });

    for (final invalidDeviation in <({String name, Object? value})>[
      (
        name: 'unknown key',
        value: <String, Object?>{
          'issue': 3,
          'rationale': 'reason',
          'unknown': true,
        },
      ),
      (
        name: 'non-integer issue',
        value: <String, Object?>{'issue': '3', 'rationale': 'reason'},
      ),
      (
        name: 'empty rationale',
        value: <String, Object?>{'issue': 3, 'rationale': ''},
      ),
      (
        name: 'blank rationale',
        value: <String, Object?>{'issue': 3, 'rationale': '   '},
      ),
    ]) {
      test('不正なdeviation provenance ${invalidDeviation.name}を拒否する', () {
        final fixture = _validFixture();
        _onlyCase(fixture)
          ..['name'] = 'issue-3-second-line-inline-wins-over-search'
          ..['deviation'] = invalidDeviation.value;

        expect(
          () => parseAstGoldenFixture(fixture),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('未承認caseへのwell-formed deviationを拒否する', () {
      final fixture = _validFixture();
      _onlyCase(fixture)['deviation'] = <String, Object?>{
        'issue': 3,
        'rationale': 'reason',
      };

      expect(
        () => parseAstGoldenFixture(fixture),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('not an approved project deviation'),
          ),
        ),
      );
    });

    for (final invalidCase in <({String name, Map<String, Object?> node})>[
      (
        name: 'leaf propertyのwrong typeを拒否する',
        node: _node('text', {'text': 42}),
      ),
      (
        name: '必要property欠落を拒否する',
        node: _node('text', const {}),
      ),
      (
        name: '未知の追加propertyを拒否する',
        node: _node('text', {'text': 'ok', 'unknown': true}),
      ),
      (
        name: 'leaf nodeのchildrenを拒否する',
        node: _node(
          'text',
          {
            'text': 'parent',
          },
          [
            _node('text', {'text': 'child'}),
          ],
        ),
      ),
      (
        name: 'container nodeの追加propertyを拒否する',
        node: _node('bold', {'unknown': true}),
      ),
      (
        name: 'nested nodeの不正propertyを拒否する',
        node: _node('bold', const {}, [
          _node('text', {'text': false}),
        ]),
      ),
      (
        name: 'url bracketsのwrong typeを拒否する',
        node: _node('url', {
          'url': 'https://example.com',
          'brackets': 'false',
        }),
      ),
      (
        name: 'mention hostのwrong nullable typeを拒否する',
        node: _node('mention', {
          'username': 'user',
          'host': false,
          'acct': '@user',
        }),
      ),
      (
        name: 'codeBlock languageのwrong nullable typeを拒否する',
        node: _node('codeBlock', {'code': 'x', 'language': false}),
      ),
      (
        name: 'fn argsの非String/bool値を拒否する',
        node: _node('fn', {
          'name': 'spin',
          'args': {'speed': 2},
        }),
      ),
      (
        name: 'search content欠落を拒否する',
        node: _node('search', {'query': 'MFM'}),
      ),
    ]) {
      test(invalidCase.name, () {
        expect(
          () => parseAstGoldenFixture(_fixtureWithNode(invalidCase.node)),
          throwsA(isA<FormatException>()),
        );
      });
    }
  });
}

Map<String, Object?> _validFixture() {
  return _fixtureWithNode(
    _node('text', {'text': 'text'}),
  );
}

Map<String, Object?> _fixtureWithNode(Map<String, Object?> node) {
  return <String, Object?>{
    'schemaVersion': astGoldenSchemaVersion,
    'compatibilityBasis': <String, Object?>{
      'implementation': 'mfm.js',
      'branch': 'develop',
      'commit': mfmJsCompatibilityCommit,
      'expectations': 'Manually reviewed test fixture.',
    },
    'cases': <Object?>[
      <String, Object?>{
        'name': 'valid-case',
        'parser': 'full',
        'input': 'text',
        'expected': <Object?>[node],
      },
    ],
  };
}

Map<String, Object?> _onlyCase(Map<String, Object?> fixture) {
  final cases = fixture['cases']! as List<Object?>;
  return cases.single! as Map<String, Object?>;
}

Map<String, Object?> _node(
  String type,
  Map<String, Object?> props, [
  List<Object?> children = const [],
]) {
  return <String, Object?>{
    'type': type,
    'props': props,
    'children': children,
  };
}
