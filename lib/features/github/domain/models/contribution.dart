import 'package:os_project_finder/features/github/domain/models/issue.dart';

/// Progress on an issue the user decided to work on.
enum ContributionStatus { saved, inProgress, completed }

extension ContributionStatusX on ContributionStatus {
  String get label => switch (this) {
        ContributionStatus.saved => 'Saved',
        ContributionStatus.inProgress => 'In progress',
        ContributionStatus.completed => 'Completed',
      };
}

/// A locally tracked contribution: the issue plus the user's status.
///
/// Plain class (not freezed) because it never crosses the network and its
/// JSON shape is app-defined.
class Contribution {
  const Contribution({
    required this.issue,
    required this.status,
    required this.updatedAt,
  });

  final Issue issue;
  final ContributionStatus status;
  final DateTime updatedAt;

  Contribution copyWith({ContributionStatus? status}) => Contribution(
        issue: issue,
        status: status ?? this.status,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'issue': issue.toJson(),
        'status': status.name,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Contribution.fromJson(Map<String, dynamic> json) => Contribution(
        issue: Issue.fromJson(json['issue'] as Map<String, dynamic>),
        status: ContributionStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ContributionStatus.saved,
        ),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
                DateTime.now(),
      );
}
