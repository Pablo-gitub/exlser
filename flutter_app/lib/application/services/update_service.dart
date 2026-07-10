import 'package:exlser/data/services/github_release_models.dart';

enum DesktopUpdatePlatform {
  macos,
  windows,
  linux,
  unsupported,
}

class UpdateCheckResult {
  final bool isPlatformSupported;
  final bool isUpdateAvailable;
  final GitHubRelease? latestRelease;
  final GitHubReleaseAsset? platformAsset;
  final String? latestVersion;

  const UpdateCheckResult._({
    required this.isPlatformSupported,
    required this.isUpdateAvailable,
    required this.latestRelease,
    required this.platformAsset,
    required this.latestVersion,
  });

  const UpdateCheckResult.unsupportedPlatform()
      : this._(
          isPlatformSupported: false,
          isUpdateAvailable: false,
          latestRelease: null,
          platformAsset: null,
          latestVersion: null,
        );

  const UpdateCheckResult.upToDate({
    required GitHubRelease latestRelease,
    required String latestVersion,
  }) : this._(
          isPlatformSupported: true,
          isUpdateAvailable: false,
          latestRelease: latestRelease,
          platformAsset: null,
          latestVersion: latestVersion,
        );

  const UpdateCheckResult.updateAvailable({
    required GitHubRelease latestRelease,
    required GitHubReleaseAsset? platformAsset,
    required String latestVersion,
  }) : this._(
          isPlatformSupported: true,
          isUpdateAvailable: true,
          latestRelease: latestRelease,
          platformAsset: platformAsset,
          latestVersion: latestVersion,
        );

  Uri? get updateUri =>
      platformAsset?.browserDownloadUrl ?? latestRelease?.htmlUrl;
}

class UpdateCheckException implements Exception {
  final String message;

  const UpdateCheckException(this.message);

  @override
  String toString() => 'UpdateCheckException: $message';
}

class UpdateService {
  final GitHubReleaseClient releaseClient;
  final String owner;
  final String repo;
  final String currentVersion;
  final String desktopTagPrefix;

  const UpdateService({
    required this.releaseClient,
    required this.owner,
    required this.repo,
    required this.currentVersion,
    this.desktopTagPrefix = 'desktop-v',
  });

  Future<UpdateCheckResult> checkForUpdate({
    required DesktopUpdatePlatform platform,
  }) async {
    if (platform == DesktopUpdatePlatform.unsupported) {
      return const UpdateCheckResult.unsupportedPlatform();
    }

    final releases = await releaseClient.fetchReleases(
      owner: owner,
      repo: repo,
    );
    final latestRelease = _latestDesktopRelease(releases);

    if (latestRelease == null) {
      throw const UpdateCheckException('No desktop release was found.');
    }

    final latestVersion = _releaseVersionFromTag(latestRelease.tagName);
    final current = AppReleaseVersion.parse(currentVersion);

    if (latestVersion.compareTo(current) <= 0) {
      return UpdateCheckResult.upToDate(
        latestRelease: latestRelease,
        latestVersion: latestVersion.toString(),
      );
    }

    return UpdateCheckResult.updateAvailable(
      latestRelease: latestRelease,
      platformAsset: _assetForPlatform(latestRelease.assets, platform),
      latestVersion: latestVersion.toString(),
    );
  }

  GitHubRelease? _latestDesktopRelease(List<GitHubRelease> releases) {
    final candidates = releases.where((release) {
      return !release.draft &&
          !release.prerelease &&
          release.tagName.toLowerCase().startsWith(
                desktopTagPrefix.toLowerCase(),
              );
    }).toList();

    candidates.sort((left, right) {
      final leftVersion = _releaseVersionFromTag(left.tagName);
      final rightVersion = _releaseVersionFromTag(right.tagName);
      return rightVersion.compareTo(leftVersion);
    });

    return candidates.isEmpty ? null : candidates.first;
  }

  AppReleaseVersion _releaseVersionFromTag(String tagName) {
    final normalizedTag = tagName.trim().toLowerCase();
    final normalizedPrefix = desktopTagPrefix.toLowerCase();

    if (!normalizedTag.startsWith(normalizedPrefix)) {
      throw FormatException('Unexpected desktop release tag: $tagName');
    }

    return AppReleaseVersion.parse(
      tagName.substring(desktopTagPrefix.length),
    );
  }

  GitHubReleaseAsset? _assetForPlatform(
    List<GitHubReleaseAsset> assets,
    DesktopUpdatePlatform platform,
  ) {
    final hints = switch (platform) {
      DesktopUpdatePlatform.macos => const ['macos', 'darwin', 'osx', '.dmg'],
      DesktopUpdatePlatform.windows => const [
          'windows',
          '.exe',
          '.msi',
          'msix'
        ],
      DesktopUpdatePlatform.linux => const [
          'linux',
          'appimage',
          '.deb',
          '.rpm',
          'tar.gz',
        ],
      DesktopUpdatePlatform.unsupported => const <String>[],
    };

    for (final hint in hints) {
      for (final asset in assets) {
        if (asset.name.toLowerCase().contains(hint)) {
          return asset;
        }
      }
    }

    return null;
  }
}

class AppReleaseVersion implements Comparable<AppReleaseVersion> {
  final int major;
  final int minor;
  final int patch;
  final int build;

  const AppReleaseVersion({
    required this.major,
    required this.minor,
    required this.patch,
    required this.build,
  });

  factory AppReleaseVersion.parse(String value) {
    var normalized = value.trim();

    if (normalized.startsWith('v')) {
      normalized = normalized.substring(1);
    }

    final buildSplit = normalized.split('+');
    final versionPart = buildSplit.first.split('-').first;
    final versionNumbers = versionPart.split('.');

    if (versionNumbers.isEmpty || versionNumbers.length > 3) {
      throw FormatException('Invalid version: $value');
    }

    int parsePart(int index) {
      if (index >= versionNumbers.length) {
        return 0;
      }
      return int.parse(versionNumbers[index]);
    }

    return AppReleaseVersion(
      major: parsePart(0),
      minor: parsePart(1),
      patch: parsePart(2),
      build: buildSplit.length > 1 ? int.parse(buildSplit[1]) : 0,
    );
  }

  @override
  int compareTo(AppReleaseVersion other) {
    final comparisons = [
      major.compareTo(other.major),
      minor.compareTo(other.minor),
      patch.compareTo(other.patch),
      build.compareTo(other.build),
    ];

    return comparisons.firstWhere(
      (comparison) => comparison != 0,
      orElse: () => 0,
    );
  }

  @override
  String toString() {
    if (build == 0) {
      return '$major.$minor.$patch';
    }
    return '$major.$minor.$patch+$build';
  }
}
