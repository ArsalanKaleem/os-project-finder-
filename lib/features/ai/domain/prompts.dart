import 'package:os_project_finder/features/github/domain/models/issue.dart';
import 'package:os_project_finder/features/github/domain/models/repo.dart';

/// Prompt templates for every AI action in the app.
///
/// Deliberately centralised so behaviour (tone, structure, the "no full
/// solutions" rule) can be tuned in one place.
abstract final class Prompts {
  static const _persona =
      'You are a friendly open source mentor helping a newcomer make their '
      'first contributions. Be encouraging, concrete, and concise. '
      'Answer in markdown.';

  static String _issueContext(Issue issue) {
    final body = (issue.body ?? '').trim();
    final truncated =
        body.length > 4000 ? '${body.substring(0, 4000)}…' : body;
    return '''
Repository: ${issue.repoFullName}
Issue #${issue.number}: ${issue.title}
Labels: ${issue.labels.map((l) => l.name).join(', ')}
Description:
$truncated''';
  }

  /// Explain an issue in simple terms + difficulty + prerequisites + links.
  static String explainIssue(Issue issue) => '''
$_persona

Analyse this GitHub issue for a beginner:

${_issueContext(issue)}

Respond with exactly these sections:
## What this issue is about
2-4 plain-language sentences, no jargon.
## Difficulty
One of **Beginner**, **Intermediate**, or **Advanced**, with a one-sentence reason.
## Skills you'll need
Bullet list of prerequisite skills or technologies.
## Where to learn them
Bullet list of 3-5 high-quality free resources (official docs first) with URLs.''';

  /// Hints and approach — explicitly not a full solution.
  static String implementationHints(Issue issue) => '''
$_persona

Give implementation guidance for this issue:

${_issueContext(issue)}

Important rules:
- Do NOT write the full solution or complete code.
- Give a suggested step-by-step approach, files/areas to look at, and
  small illustrative snippets only where a concept needs it.
- End with tips for asking the maintainers good questions.

Respond with sections: ## Suggested approach, ## Things to investigate,
## Pitfalls to avoid, ## Before you open the PR.''';

  /// Step-by-step learning roadmap tailored to one repository.
  static String learningRoadmap(Repo repo) => '''
$_persona

Create a step-by-step learning roadmap for someone who wants to contribute
to this repository:

Repository: ${repo.fullName}
Description: ${repo.description ?? 'n/a'}
Main language: ${repo.language ?? 'unknown'}
Topics: ${repo.topics.join(', ')}

Respond with a numbered roadmap of 6-10 steps, from "understand the basics"
to "open your first pull request". For each step give: what to do, why it
matters, and one free resource with a URL. Finish with a short motivating
note.''';

  /// Compress a long README to the essentials.
  static String summarizeReadme(Repo repo, String readme) {
    final truncated =
        readme.length > 12000 ? '${readme.substring(0, 12000)}…' : readme;
    return '''
$_persona

Summarise this project's README for someone deciding whether to contribute.

Repository: ${repo.fullName}

README:
$truncated

Respond with: ## What it does (2-3 sentences), ## Tech stack,
## How to get started, ## Good to know for contributors.''';
  }
}
