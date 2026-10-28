/// GitHub repository identity, injected when the app is built.
///
/// CI passes `--dart-define=C001APK_REPOSITORY=<owner>/<repo>` from
/// `${{ github.repository }}`, so a fork checks its own Releases and links
/// back to its own documentation. Local builds can use
/// `dart tool/build_release.dart <target> ...`, which reads `origin`.
///
/// The default is this repository so a plain `flutter build` still points
/// somewhere valid; forks should build through CI or the helper.
class AppRepository {
  AppRepository._();

  static const String slug = String.fromEnvironment(
    'C001APK_REPOSITORY',
    defaultValue: '403bug/c001apk',
  );

  static const String webHost = 'github.com';
  static const String apiHost = 'api.github.com';

  static const String pageUrl = 'https://$webHost/$slug';
  static const String releasesUrl = '$pageUrl/releases';
  static const String latestReleaseApi =
      'https://$apiHost/repos/$slug/releases/latest';
  static const String releasePathPrefix = '/$slug/releases/';

  /// Announcements default to [slug]. A fork that keeps using upstream notices
  /// can set `C001APK_ANNOUNCEMENTS_REPOSITORY` separately; a missing branch
  /// simply yields an empty feed.
  static const String announcementsSlug = String.fromEnvironment(
    'C001APK_ANNOUNCEMENTS_REPOSITORY',
    defaultValue: slug,
  );

  static const String announcementsBase =
      'https://raw.githubusercontent.com/$announcementsSlug/announcements/announcements/';

  /// Content-filter rules default to [slug]; a fork without a `filters`
  /// branch keeps using the bundled rule set. Override with
  /// `C001APK_FILTERS_REPOSITORY` when the rules live elsewhere.
  static const String filtersSlug = String.fromEnvironment(
    'C001APK_FILTERS_REPOSITORY',
    defaultValue: slug,
  );

  static const String filtersUrl =
      'https://raw.githubusercontent.com/$filtersSlug/filters/rules.json';
}
