import 'dart:io';

void main(List<String> arguments) {
  final file = File(arguments.isEmpty ? 'coverage/lcov.info' : arguments.first);
  if (!file.existsSync()) {
    stderr.writeln('Coverage file not found: ${file.path}');
    exitCode = 1;
    return;
  }

  final overall = _Coverage();
  final critical = _Coverage();
  for (final record in file.readAsStringSync().split('end_of_record')) {
    final source = _value(record, 'SF:')?.replaceAll('\\', '/');
    if (source == null || source.endsWith('.g.dart')) continue;
    final found = int.tryParse(_value(record, 'LF:') ?? '') ?? 0;
    final hit = int.tryParse(_value(record, 'LH:') ?? '') ?? 0;
    overall.add(hit, found);
    if (RegExp(
      r'^lib/(core|data|state|playback|downloads)/',
    ).hasMatch(source)) {
      critical.add(hit, found);
    }
  }

  _report('Overall non-generated', overall, 80);
  _report('Core/data/state/playback/downloads', critical, 90);
}

String? _value(String record, String prefix) {
  for (final line in record.split('\n')) {
    if (line.startsWith(prefix)) return line.substring(prefix.length).trim();
  }
  return null;
}

void _report(String name, _Coverage coverage, double minimum) {
  final percent = coverage.percent;
  stdout.writeln(
    '$name coverage: ${coverage.hit}/${coverage.found} '
    '(${percent.toStringAsFixed(2)}%; required ${minimum.toStringAsFixed(0)}%)',
  );
  if (coverage.found == 0 || percent < minimum) exitCode = 1;
}

class _Coverage {
  int hit = 0;
  int found = 0;

  double get percent => found == 0 ? 0 : hit * 100 / found;

  void add(int hit, int found) {
    this.hit += hit;
    this.found += found;
  }
}
