# Contributing

Thanks for your interest! This project aims to be a friendly first contribution target.

## Quick start

1. Fork and clone the repo.
2. `flutter create . --platforms=web` (or your target), then `flutter pub get`.
3. `dart run build_runner build --delete-conflicting-outputs`.
4. `flutter run -d chrome`.

## Ground rules

- **Small PRs** are easier to review than big ones.
- Run `flutter analyze` and `flutter test` before opening a PR — both must pass.
- Follow the existing feature-first structure (`lib/features/<feature>/…`); shared code goes in `lib/core/`.
- New remote calls belong in `lib/features/github/data/` (or `ai/data/`) and must map errors through `ApiException`.
- UI must remain responsive (test at phone and desktop widths) and support both themes.
- Keep AI prompt changes inside `lib/features/ai/domain/prompts.dart`.

## Good first contributions

- Add a language or issue label to `AppConstants`.
- Improve empty/error states or accessibility (semantics labels, focus order).
- Add tests (start with `test/`).
- Add a new sort/filter option to search.

## Reporting bugs

Open an issue with: platform, Flutter version, steps to reproduce, and what you expected to happen.
