<div align="center">

# 🧭 Open Source Project Finder

**Discover trending repositories, find beginner-friendly issues, and get AI-powered guidance for your first open source contribution.**

Built with Flutter for Web, Android, Windows, macOS, and Linux — from a single codebase.

[![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-web%20%7C%20android%20%7C%20windows%20%7C%20macos%20%7C%20linux-informational)]()

[Report a Bug](https://github.com/ArsalanKaleem/os-project-finder-/issues) · [Request a Feature](https://github.com/ArsalanKaleem/os-project-finder-/issues) · [Contributing](CONTRIBUTING.md)

</div>

---

## About

Most developers who want to contribute to open source hit the same wall: **they don't know where to start.** Trending pages are noisy, issue trackers are overwhelming, and it's not always clear which issues are actually approachable for a newcomer.

**Open Source Project Finder** solves that. It surfaces trending and beginner-friendly repositories, filters GitHub issues down to the ones labeled for newcomers, and uses AI to explain what an issue actually involves — its difficulty, the skills it requires, and a suggested approach — without ever handing you the full solution. It's built entirely on **free APIs**, requires no backend of its own, and runs identically across five platforms from one Flutter codebase.

---

## ✨ Features

### Discover
- 🔥 Trending repositories by day, week, or month — filterable by language
- 🔎 Full repository search with language, topic, minimum-star, and sort filters
- ⚡ "Active this week" feed of recently updated, popular projects
- ♾️ Infinite scrolling, pull-to-refresh, skeleton loading states, and clear error/empty states

### Contribute
- 🎯 Issue finder scoped to `good first issue`, `help wanted`, `documentation`, and more — filterable by language and keyword, unassigned issues only
- 📈 Local contribution tracker: mark issues as *Saved → In Progress → Completed*
- 🔖 Offline bookmarks for repositories and issues (bookmarked READMEs are cached for offline reading)
- 🕘 Recently viewed repositories and search history

### Understand
- 📄 Repository detail pages with rendered Markdown READMEs and syntax-highlighted code blocks
- 👤 GitHub profile viewer for any user or organization
- 🧠 Optional contribution insights via the GitHub GraphQL API (good-first-issue counts, help-wanted counts, commit totals) when a personal access token is added

### AI Assistant (Gemini free tier)
- 🗣️ Plain-language explanations of any issue
- 🎚️ Difficulty estimation (Beginner / Intermediate / Advanced) with reasoning
- 📚 Recommended learning resources and prerequisite skills
- 🧭 Implementation guidance — approach and pitfalls, deliberately never a full solution
- 🗺️ Step-by-step learning roadmaps tailored to a specific repository
- 📝 README summarization for long or dense projects
- 💬 Follow-up Q&A in a persistent chat interface

### Design
- 🌙 Dark theme by default, with an optional light theme
- 🎨 Custom Material 3 palette (`#101820` / `#F2AA4C`)
- 🖱️ Hover effects and smooth transitions on desktop and web
- 📱 Fully responsive — bottom navigation on mobile, navigation rail on tablet and desktop

---

## 🖼️ Screenshots

*(Add screenshots or a short demo GIF here once available — the Home, Issue Finder, Repo Details, and AI Assistant screens make for a strong preview.)*

---

## 🏗️ Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Web, Android, Windows, macOS, Linux) |
| State management | Riverpod |
| Navigation | GoRouter (`StatefulShellRoute`) |
| Networking | Dio |
| Models | Freezed + json_serializable |
| Local storage | Hive (cross-platform, including Web) |
| Markdown & code rendering | flutter_markdown + flutter_highlight |
| Data sources | GitHub REST API, GitHub GraphQL API, Gemini API (free tier) |

Architecture follows a **clean, feature-first structure** with a repository pattern separating data sources from UI — see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for a full breakdown.

```
lib/
├── core/            # theme, router, network, storage, shared widgets & utils
└── features/
    ├── github/      # data sources (REST + GraphQL) and domain models
    ├── explore/     # home (trending) + search
    ├── issues/      # beginner-friendly issue finder
    ├── repo_details/# repository page (README / issues / about)
    ├── ai/          # Gemini service, prompts, assistant UI
    ├── bookmarks/   # bookmarks + contribution tracking (offline)
    ├── profile/     # GitHub profile viewer
    ├── settings/    # theme, API keys, data management
    └── about/
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.27 or newer (Dart ≥ 3.3)

### Installation

```bash
git clone https://github.com/ArsalanKaleem/os-project-finder-.git
cd os-project-finder-

# Generate platform folders for your targets
flutter create . --platforms=web,android,windows,macos,linux

# Install dependencies
flutter pub get

# Generate Freezed / JSON models — required before first run
dart run build_runner build --delete-conflicting-outputs

# Run
flutter run -d chrome     # Web
flutter run -d windows    # or macos / linux
flutter run                # connected Android device or emulator
```

> Generated `*.freezed.dart` / `*.g.dart` files are gitignored by design — the build_runner step above recreates them locally.

### API Keys (both free, both optional)

| Key | Purpose | Where to get it |
|---|---|---|
| **Gemini API key** | Enables all AI features | [aistudio.google.com/apikey](https://aistudio.google.com/apikey) → add in **Settings** |
| **GitHub personal access token** | Raises the rate limit from ~60/hr to 5,000/hr and unlocks GraphQL contribution insights (no scopes required) | GitHub → Settings → Developer settings → add in **Settings** |

All keys are stored locally on your device and sent only to their respective APIs — this app has no backend of its own.

---

## 🤝 Contributing

Contributions are genuinely welcome — an app built to help people make their first open source contribution should be an approachable one to contribute to. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for setup details, coding conventions, and good first issues.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m "Add your feature"`)
4. Push to your branch (`git push origin feature/your-feature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for details.

---

## 👤 Author

**Arsalan Kaleem**

- GitHub: [@ArsalanKaleem](https://github.com/ArsalanKaleem)
- LinkedIn: [linkedin.com/in/arsalankaleem](https://www.linkedin.com/in/arsalankaleem)
- Portfolio: *[add your portfolio URL here]*

If this project helped you make your first open source contribution, consider giving it a ⭐ — it helps others find it too.