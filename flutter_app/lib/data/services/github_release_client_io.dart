import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'github_release_models.dart';

GitHubReleaseClient createPlatformGitHubReleaseClient() {
  return IoGitHubReleaseClient();
}

class IoGitHubReleaseClient implements GitHubReleaseClient {
  final Duration timeout;

  IoGitHubReleaseClient({
    this.timeout = const Duration(seconds: 15),
  });

  @override
  Future<List<GitHubRelease>> fetchReleases({
    required String owner,
    required String repo,
    int perPage = 20,
  }) async {
    final client = HttpClient();
    final uri = Uri.https(
      'api.github.com',
      '/repos/$owner/$repo/releases',
      {
        'per_page': perPage.clamp(1, 100).toString(),
      },
    );

    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      request.headers.set(HttpHeaders.userAgentHeader, 'Exlser update checker');
      request.headers.set('X-GitHub-Api-Version', '2022-11-28');

      final response = await request.close().timeout(timeout);
      final body = await utf8.decoder.bind(response).join().timeout(timeout);

      if (response.statusCode != HttpStatus.ok) {
        throw GitHubReleaseClientException(
          'GitHub returned an unexpected response.',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! List) {
        throw const FormatException('Invalid GitHub releases payload.');
      }

      return decoded.map((release) {
        if (release is Map<String, dynamic>) {
          return GitHubRelease.fromJson(release);
        }
        if (release is Map) {
          return GitHubRelease.fromJson(Map<String, dynamic>.from(release));
        }
        throw const FormatException('Invalid GitHub release payload.');
      }).toList(growable: false);
    } on TimeoutException catch (error) {
      throw GitHubReleaseClientException(error.message ?? 'Request timed out.');
    } on SocketException catch (error) {
      throw GitHubReleaseClientException(error.message);
    } finally {
      client.close(force: true);
    }
  }
}
