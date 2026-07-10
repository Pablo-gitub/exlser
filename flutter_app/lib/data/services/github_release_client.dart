import 'github_release_client_stub.dart'
    if (dart.library.io) 'github_release_client_io.dart';
import 'github_release_models.dart';

GitHubReleaseClient createGitHubReleaseClient() {
  return createPlatformGitHubReleaseClient();
}
