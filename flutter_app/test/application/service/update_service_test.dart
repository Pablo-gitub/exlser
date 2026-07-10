import 'package:exlser/application/services/update_service.dart';
import 'package:exlser/data/services/github_release_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateService', () {
    test('finds newer desktop release and platform asset', () async {
      final client = _FakeGitHubReleaseClient([
        _release(tagName: 'android-v9.0.0'),
        _release(
          tagName: 'desktop-v2.1.0',
          assets: [
            _asset('exlser-2.1.0-macos.zip'),
            _asset('exlser-2.1.0-windows.zip'),
          ],
        ),
      ]);
      final service = _service(client, currentVersion: '2.0.1+201');

      final result = await service.checkForUpdate(
        platform: DesktopUpdatePlatform.macos,
      );

      expect(result.isPlatformSupported, isTrue);
      expect(result.isUpdateAvailable, isTrue);
      expect(result.latestVersion, '2.1.0');
      expect(result.platformAsset?.name, 'exlser-2.1.0-macos.zip');
      expect(result.updateUri, Uri.parse('https://example.com/download.zip'));
    });

    test('sorts desktop releases by semantic version', () async {
      final client = _FakeGitHubReleaseClient([
        _release(tagName: 'desktop-v2.0.9'),
        _release(tagName: 'desktop-v2.0.10'),
      ]);
      final service = _service(client, currentVersion: '2.0.1+201');

      final result = await service.checkForUpdate(
        platform: DesktopUpdatePlatform.linux,
      );

      expect(result.isUpdateAvailable, isTrue);
      expect(result.latestRelease?.tagName, 'desktop-v2.0.10');
      expect(result.latestVersion, '2.0.10');
    });

    test('reports up to date when latest desktop release is not newer',
        () async {
      final client = _FakeGitHubReleaseClient([
        _release(tagName: 'desktop-v2.0.1'),
      ]);
      final service = _service(client, currentVersion: '2.0.1+201');

      final result = await service.checkForUpdate(
        platform: DesktopUpdatePlatform.windows,
      );

      expect(result.isPlatformSupported, isTrue);
      expect(result.isUpdateAvailable, isFalse);
      expect(result.latestVersion, '2.0.1');
    });

    test('does not call GitHub on unsupported platforms', () async {
      final client = _FakeGitHubReleaseClient([
        _release(tagName: 'desktop-v2.1.0'),
      ]);
      final service = _service(client, currentVersion: '2.0.1+201');

      final result = await service.checkForUpdate(
        platform: DesktopUpdatePlatform.unsupported,
      );

      expect(result.isPlatformSupported, isFalse);
      expect(result.isUpdateAvailable, isFalse);
      expect(client.calls, 0);
    });
  });
}

UpdateService _service(
  GitHubReleaseClient client, {
  required String currentVersion,
}) {
  return UpdateService(
    releaseClient: client,
    owner: 'owner',
    repo: 'repo',
    currentVersion: currentVersion,
  );
}

GitHubRelease _release({
  required String tagName,
  bool draft = false,
  bool prerelease = false,
  List<GitHubReleaseAsset> assets = const [],
}) {
  return GitHubRelease(
    tagName: tagName,
    name: tagName,
    htmlUrl: Uri.parse('https://example.com/releases/$tagName'),
    body: null,
    draft: draft,
    prerelease: prerelease,
    assets: assets,
  );
}

GitHubReleaseAsset _asset(String name) {
  return GitHubReleaseAsset(
    name: name,
    browserDownloadUrl: Uri.parse('https://example.com/download.zip'),
    size: 1024,
  );
}

class _FakeGitHubReleaseClient implements GitHubReleaseClient {
  final List<GitHubRelease> releases;
  int calls = 0;

  _FakeGitHubReleaseClient(this.releases);

  @override
  Future<List<GitHubRelease>> fetchReleases({
    required String owner,
    required String repo,
    int perPage = 20,
  }) async {
    calls++;
    return releases;
  }
}
