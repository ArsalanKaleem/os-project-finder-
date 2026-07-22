import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:forgeos/features/github/domain/models/repo.dart';

part 'issue.freezed.dart';
part 'issue.g.dart';

/// A GitHub issue as returned by the issue search endpoint.
@freezed
class Issue with _$Issue {
  const Issue._();

  const factory Issue({
    required int id,
    required int number,
    required String title,
    @JsonKey(name: 'html_url') required String htmlUrl,
    String? body,
    @Default('open') String state,
    @Default(0) int comments,
    @Default(<IssueLabel>[]) List<IssueLabel> labels,
    Owner? user,
    @JsonKey(name: 'repository_url') @Default('') String repositoryUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Issue;

  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);

  /// `owner/name`, derived from the API `repository_url`.
  String get repoFullName {
    final idx = repositoryUrl.indexOf('/repos/');
    if (idx == -1) return '';
    return repositoryUrl.substring(idx + '/repos/'.length);
  }

  bool get isOpen => state == 'open';
}

/// Colored label on an issue (e.g. `good first issue`).
@freezed
class IssueLabel with _$IssueLabel {
  const factory IssueLabel({
    required String name,
    @Default('808080') String color,
  }) = _IssueLabel;

  factory IssueLabel.fromJson(Map<String, dynamic> json) =>
      _$IssueLabelFromJson(json);
}
