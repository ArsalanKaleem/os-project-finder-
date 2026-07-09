# Architecture

## Goals

1. **Feature-first** organisation so contributors can find everything about one feature in one folder.
2. **Unidirectional data flow** with Riverpod: widgets watch providers; providers call data sources; data sources talk to APIs/storage.
3. **Offline-friendly**: bookmarking persists the full payload locally; details pages fall back to it when offline.
4. **One codebase, six platforms**: no platform channels, only packages with web + desktop support.

## Layers

```
Widgets (screens, cards)
   │  ref.watch(...)
Providers (Notifier / AsyncNotifier / FutureProvider)
   │  method calls
Data sources (GithubApi, GithubGraphql, GeminiApi, LocalStorage)
   │
GitHub REST / GitHub GraphQL / Gemini REST / Hive
```

### Domain models (`features/github/domain/models`)
Freezed + json_serializable immutable models (`Repo`, `Issue`, `GithubUser`, …).
Run `dart run build_runner build --delete-conflicting-outputs` after editing them.
`Contribution` is a plain class because its JSON shape is app-defined and never
crosses the network.

### Data sources
- **`GithubApi`** (REST): search/trending/details/readme/contributors/languages/issues/users. All failures are normalised to `ApiException` with user-presentable messages (rate limits get a dedicated one).
- **`GithubGraphql`**: used *opportunistically* — GraphQL requires auth, so it only runs when the user added a token, enriching the About tab with issue counts and commit totals. Failures degrade silently to REST-only data.
- **`GeminiApi`**: single `generate(conversation)` method against `models/{model}:generateContent`. Gemini is stateless, so the whole chat is resent each turn. Prompt templates live in `ai/domain/prompts.dart`.
- **`LocalStorage`**: Hive boxes storing JSON strings (no type adapters ⇒ no extra codegen, identical behaviour on web/desktop/mobile). Boxes: settings, repo/issue bookmarks, contributions, recently viewed, search history, README cache.

### State management
- Plain Riverpod (no riverpod_generator) to keep codegen limited to models.
- Paginated lists use an `AsyncNotifier` family keyed by an immutable filter object (`RepoSearchFilter`, `IssueFilter`) holding a `PaginatedState<T>` with `loadMore()`.
- Local collections (bookmarks, history, contributions) are synchronous `Notifier`s that mirror Hive.

### Navigation
GoRouter `StatefulShellRoute.indexedStack` with five branches (Home, Search, Issues, Saved, Settings), each keeping its own stack. Repo details, profiles, and About are pushed on the root navigator so they cover the rail/bar. `AdaptiveShell` renders a bottom `NavigationBar` under 640 px and a `NavigationRail` above it (extended ≥ 1440 px).

### Theming & responsiveness
- `AppTheme` builds Material 3 dark (default) and light themes around `#101820` and `#F2AA4C`.
- `Breakpoints` + `ResponsiveContext` extension centralise breakpoints; `CenteredContent` caps content width at 1200 px.
- `HoverEffect` adds desktop hover lift/glow without affecting touch platforms.

### Offline strategy
- Bookmarking a repo/issue writes its **full JSON** to Hive — that *is* the cache.
- `repoDetailsProvider` and `readmeProvider` try the network, then fall back to the bookmark / README cache.
- Settings, history, recently-viewed and contributions are local-only by design.
