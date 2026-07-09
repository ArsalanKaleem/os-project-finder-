import 'package:freezed_annotation/freezed_annotation.dart';

part 'github_user.freezed.dart';
part 'github_user.g.dart';

/// Full public profile of a GitHub user or organization.
@freezed
class GithubUser with _$GithubUser {
  const factory GithubUser({
    required String login,
    @JsonKey(name: 'avatar_url') @Default('') String avatarUrl,
    @JsonKey(name: 'html_url') @Default('') String htmlUrl,
    String? name,
    String? bio,
    String? company,
    String? blog,
    String? location,
    @Default(0) int followers,
    @Default(0) int following,
    @JsonKey(name: 'public_repos') @Default(0) int publicRepos,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _GithubUser;

  factory GithubUser.fromJson(Map<String, dynamic> json) =>
      _$GithubUserFromJson(json);
}
