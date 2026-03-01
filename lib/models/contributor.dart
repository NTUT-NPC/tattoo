class Contributor {
  final String login;
  final String avatarUrl;
  final String htmlUrl;
  final String type;

  Contributor({
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.type,
  });

  factory Contributor.fromJson(Map<String, dynamic> json) {
    return Contributor(
      login: json['login'] as String,
      avatarUrl: json['avatar_url'] as String,
      htmlUrl: json['html_url'] as String,
      type: json['type'] as String,
    );
  }

  bool get isBot => type == 'Bot';
}
