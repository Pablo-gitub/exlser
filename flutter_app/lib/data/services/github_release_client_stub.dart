import 'github_release_models.dart';

GitHubReleaseClient createPlatformGitHubReleaseClient() {
  return const UnsupportedGitHubReleaseClient();
}

class UnsupportedGitHubReleaseClient implements GitHubReleaseClient {
  const UnsupportedGitHubReleaseClient();

  @override
  Future<List<GitHubRelease>> fetchReleases({
    required String owner,
    required String repo,
    int perPage = 20,
  }) {
    throw const GitHubReleaseClientException(
      'GitHub release checks are not available on this platform.',
    );
  }
}
