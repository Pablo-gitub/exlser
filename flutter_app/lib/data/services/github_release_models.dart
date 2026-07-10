class GitHubReleaseAsset {
  final String name;
  final Uri browserDownloadUrl;
  final int size;

  const GitHubReleaseAsset({
    required this.name,
    required this.browserDownloadUrl,
    required this.size,
  });

  factory GitHubReleaseAsset.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final browserDownloadUrl = json['browser_download_url'];
    final size = json['size'];

    if (name is! String || browserDownloadUrl is! String) {
      throw const FormatException('Invalid GitHub release asset payload.');
    }

    return GitHubReleaseAsset(
      name: name,
      browserDownloadUrl: Uri.parse(browserDownloadUrl),
      size: size is int ? size : 0,
    );
  }
}

class GitHubRelease {
  final String tagName;
  final String name;
  final Uri htmlUrl;
  final String? body;
  final bool draft;
  final bool prerelease;
  final List<GitHubReleaseAsset> assets;

  const GitHubRelease({
    required this.tagName,
    required this.name,
    required this.htmlUrl,
    required this.body,
    required this.draft,
    required this.prerelease,
    required this.assets,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'];
    final name = json['name'];
    final htmlUrl = json['html_url'];
    final body = json['body'];
    final assets = json['assets'];

    if (tagName is! String || htmlUrl is! String) {
      throw const FormatException('Invalid GitHub release payload.');
    }

    return GitHubRelease(
      tagName: tagName,
      name: name is String && name.isNotEmpty ? name : tagName,
      htmlUrl: Uri.parse(htmlUrl),
      body: body is String ? body : null,
      draft: json['draft'] == true,
      prerelease: json['prerelease'] == true,
      assets: assets is List
          ? assets.map((asset) {
              if (asset is Map<String, dynamic>) {
                return GitHubReleaseAsset.fromJson(asset);
              }
              if (asset is Map) {
                return GitHubReleaseAsset.fromJson(
                  Map<String, dynamic>.from(asset),
                );
              }
              throw const FormatException(
                'Invalid GitHub release asset payload.',
              );
            }).toList(growable: false)
          : const [],
    );
  }
}

abstract class GitHubReleaseClient {
  Future<List<GitHubRelease>> fetchReleases({
    required String owner,
    required String repo,
    int perPage = 20,
  });
}

class GitHubReleaseClientException implements Exception {
  final String message;
  final int? statusCode;

  const GitHubReleaseClientException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() {
    if (statusCode == null) {
      return 'GitHubReleaseClientException: $message';
    }
    return 'GitHubReleaseClientException($statusCode): $message';
  }
}
