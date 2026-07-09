import 'package:freezed_annotation/freezed_annotation.dart';

part 'repo.freezed.dart';
part 'repo.g.dart';

/// A GitHub repository (subset of the REST payload the UI needs).
@freezed
class Repo with _$Repo {
  const Repo._();

  const factory Repo({
    required int id,
    required String name,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'html_url') required String htmlUrl,
    Owner? owner,
    String? description,
    String? language,
    String? homepage,
    @JsonKey(name: 'stargazers_count') @Default(0) int stars,
    @JsonKey(name: 'forks_count') @Default(0) int forks,
    @JsonKey(name: 'open_issues_count') @Default(0) int openIssues,
    @Default(<String>[]) List<String> topics,
    RepoLicense? license,
    @JsonKey(name: 'default_branch') String? defaultBranch,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'pushed_at') DateTime? pushedAt,
  }) = _Repo;

  factory Repo.fromJson(Map<String, dynamic> json) => _$RepoFromJson(json);

  String get ownerLogin => owner?.login ?? fullName.split('/').first;
  String get avatarUrl => owner?.avatarUrl ?? '';
}

/// Repository owner / any GitHub account reference.
@freezed
class Owner with _$Owner {
  const factory Owner({
    required String login,
    @JsonKey(name: 'avatar_url') @Default('') String avatarUrl,
    @JsonKey(name: 'html_url') @Default('') String htmlUrl,
    @JsonKey(name: 'contributions') int? contributions,
  }) = _Owner;

  factory Owner.fromJson(Map<String, dynamic> json) => _$OwnerFromJson(json);
}

/// Open-source license attached to a repository.
@freezed
class RepoLicense with _$RepoLicense {
  const factory RepoLicense({
    String? key,
    String? name,
    @JsonKey(name: 'spdx_id') String? spdxId,
    String? url,
  }) = _RepoLicense;

  factory RepoLicense.fromJson(Map<String, dynamic> json) =>
      _$RepoLicenseFromJson(json);
}
