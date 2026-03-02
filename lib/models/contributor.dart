/// A GitHub repository contributor.
///
/// Contains basic profile information for a GitHub user or bot that has
/// contributed to the repository.
class Contributor {
  /// The user's GitHub username.
  final String login;

  /// The URL to the user's GitHub avatar image.
  final String avatarUrl;

  /// The URL to the user's GitHub profile page.
  final String htmlUrl;

  /// The account type (typically "User" or "Bot").
  final String type;

  /// Creates a [Contributor] instance.
  Contributor({
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.type,
  });

  /// Creates a [Contributor] from a JSON map from the GitHub API.
  factory Contributor.fromJson(Map<String, dynamic> json) {
    return Contributor(
      login: json['login'] as String,
      avatarUrl: json['avatar_url'] as String,
      htmlUrl: json['html_url'] as String,
      type: json['type'] as String,
    );
  }

  /// Whether this contributor is a bot (e.g., dependabot).
  bool get isBot => type == 'Bot';
}
