import 'dart:io';

void main() {
  final scriptDir = Directory.current;
  final packageRoot = _locatePackageRoot(scriptDir) ??
      (throw Exception('Unable to find isolate_helper package root.'));

  final pubspecFile = File('${packageRoot.path}/pubspec.yaml');
  final changelogFile = File('${packageRoot.path}/CHANGELOG.md');

  if (!pubspecFile.existsSync()) {
    stderr.writeln('pubspec.yaml not found in ${packageRoot.path}');
    exit(1);
  }
  if (!changelogFile.existsSync()) {
    stderr.writeln('CHANGELOG.md not found in ${packageRoot.path}');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final versionMatch = RegExp(r'^version:\s*([^\s]+)', multiLine: true)
      .firstMatch(pubspecContent);
  if (versionMatch == null) {
    stderr.writeln('Unable to locate version in pubspec.yaml');
    exit(1);
  }

  final currentVersion = versionMatch.group(1)!;
  final changelogContent = changelogFile.readAsStringSync();
  final topEntryMatch = RegExp(r'^##\s+([0-9]+(?:\.[0-9]+)*)', multiLine: true)
      .firstMatch(changelogContent);
  final topVersion = topEntryMatch?.group(1);

  final baselineVersion = topVersion == null
      ? currentVersion
      : _maxVersion(currentVersion, topVersion);
  final newVersion = _bumpPatch(baselineVersion);

  if (currentVersion == newVersion) {
    stdout.writeln(currentVersion);
    return;
  }

  final updatedPubspec = pubspecContent.replaceFirst(
    'version: $currentVersion',
    'version: $newVersion',
  );
  pubspecFile.writeAsStringSync(updatedPubspec);

  final now = DateTime.now().toUtc();
  final date = '${_twoDigits(now.day)}/${_twoDigits(now.month)}/${now.year}';
  final commitSha = Platform.environment['GITHUB_SHA'];
  final repoSlug = Platform.environment['GITHUB_REPOSITORY'];

  final buffer = StringBuffer()
    ..writeln('## $newVersion - $date')
    ..writeln()
    ..writeln(
        '- Automated release triggered by ${commitSha != null ? _shortSha(commitSha) : 'CI'}.')
    ..writeln();

  if (commitSha != null && repoSlug != null) {
    buffer
        .writeln('- Changes: https://github.com/$repoSlug/commit/${commitSha}');
    buffer.writeln();
  }

  buffer.write(changelogContent.trimLeft());
  buffer.writeln();

  changelogFile.writeAsStringSync(buffer.toString());

  stdout.writeln(newVersion);
}

Directory? _locatePackageRoot(Directory start) {
  var dir = start.absolute;
  while (true) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      final nameMatch = RegExp(r'^name:\s*(.+)$', multiLine: true)
          .firstMatch(pubspec.readAsStringSync());
      if (nameMatch != null && nameMatch.group(1)!.trim() == 'pl_isolate') {
        return dir;
      }
    }

    final parent = dir.parent;
    if (parent.path == dir.path) {
      return null;
    }
    dir = parent;
  }
}

String _bumpPatch(String version) {
  final parts = version.split('+');
  final numberParts = parts.first
      .split('.')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  while (numberParts.length < 3) {
    numberParts.add('0');
  }

  final patch = int.tryParse(numberParts.last) ?? 0;
  numberParts[numberParts.length - 1] = (patch + 1).toString();

  final newBase = numberParts.join('.');
  if (parts.length > 1) {
    final suffix = parts.sublist(1).join('+');
    return '$newBase+$suffix';
  }
  return newBase;
}

String _maxVersion(String a, String b) => _compareVersions(a, b) >= 0 ? a : b;

int _compareVersions(String a, String b) {
  final aParts = _versionCore(a);
  final bParts = _versionCore(b);
  final length = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < length; i++) {
    final aVal = i < aParts.length ? aParts[i] : 0;
    final bVal = i < bParts.length ? bParts[i] : 0;
    if (aVal != bVal) {
      return aVal.compareTo(bVal);
    }
  }
  return 0;
}

List<int> _versionCore(String version) {
  final numeric = version.split('+').first;
  return numeric
      .split('.')
      .map((segment) => int.tryParse(segment) ?? 0)
      .toList();
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _shortSha(String sha) =>
    sha.substring(0, sha.length < 7 ? sha.length : 7);
