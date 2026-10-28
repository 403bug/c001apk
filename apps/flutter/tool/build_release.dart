import 'dart:io';

/// Builds a Flutter target with this checkout's GitHub repository injected.
///
/// CI passes `--dart-define` from `${{ github.repository }}`; this helper does
/// the same for local builds by reading `origin`, so a fork's update checks,
/// source link and documentation links point at that fork.
///
/// Usage: dart tool/build_release.dart <target> [flutter build options]
/// Example: dart tool/build_release.dart macos --release
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
        'Usage: dart tool/build_release.dart <target> [flutter build options]');
    exit(64);
  }

  final hasDefine =
      args.any((arg) => arg.startsWith('--dart-define=C001APK_REPOSITORY='));
  String? slug;
  if (!hasDefine) {
    slug = Platform.environment['C001APK_REPOSITORY']?.trim();
    if (slug == null || slug.isEmpty) slug = _originSlug();
    if (slug == null || !RegExp(r'^[^/\s]+/[^/\s]+$').hasMatch(slug)) {
      stderr.writeln('Cannot determine <owner>/<repo> from git origin. '
          'Set C001APK_REPOSITORY=owner/repo.');
      exit(64);
    }
  }

  final process = await Process.start(
    'flutter',
    [
      'build',
      ...args,
      if (slug != null) '--dart-define=C001APK_REPOSITORY=$slug',
    ],
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: _projectRoot(),
  );
  exit(await process.exitCode);
}

String _projectRoot() => File.fromUri(Platform.script).parent.parent.path;

String? _originSlug() {
  final result = Process.runSync(
    'git',
    ['remote', 'get-url', 'origin'],
    workingDirectory: _projectRoot(),
  );
  if (result.exitCode != 0) return null;
  final url = (result.stdout as String).trim();
  return RegExp(r'github\.com[:/]+([^/\s]+/[^/\s]+?)(?:\.git)?$')
      .firstMatch(url)
      ?.group(1);
}
