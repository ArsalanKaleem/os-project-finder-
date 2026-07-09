# Open Source Project Finder

**Discover trending repositories, find beginner-friendly issues, and get AI-powered guidance for your first open source contribution — on Web, Android, Windows, macOS, and Linux from a single Flutter codebase.**

Built entirely on **free APIs** (GitHub REST + GraphQL, Gemini free tier). No paid services, no accounts, no tracking. Everything you save stays on your device.

---

## ✨ Features

### Discover
- 🔥 **Trending repositories** — by day / week / month, filterable by language
- 🔎 **Powerful search** — keywords + language, topic, minimum stars, and sort order
- ⚡ **Active this week** — recently updated popular projects
- ♾️ **Infinite scrolling**, pull-to-refresh, skeleton loading, and friendly error/empty states

### Contribute
- 🎯 **Issue finder** — `good first issue`, `help wanted`, `documentation` and more, filtered by language and keyword (unassigned issues only)
- 📈 **Contribution tracker** — mark issues as *Saved → In progress → Completed*, all locally
- 🔖 **Bookmarks** — repositories and issues, stored offline (bookmarked repos and their READMEs are readable with no connection)
- 🕘 **Recently viewed** repos and **search history**

### Understand
- 📄 **Repository details** — README with Markdown rendering + **syntax-highlighted code blocks**, beginner-friendly issues, topics, license, language breakdown bar, top contributors
- 👤 **GitHub profile viewer**
- 🧠 **Contribution insights** via the GitHub **GraphQL API** (when you add an optional token): good-first-issue counts, help-wanted counts, total commits

### AI assistant (Gemini free tier — bring your own free key)
- 🗣️ **Explain an issue** in simple terms
- 🎚️ **Difficulty estimate** (Beginner / Intermediate / Advanced) + **prerequisite skills**
- 📚 **Learning resources** recommendations
- 🧭 **Implementation hints** — approach and pitfalls, deliberately *never* the full solution
- 🗺️ **Step-by-step learning roadmap** tailored to a repository
- 📝 **README summarizer** for long READMEs
- 💬 **Follow-up questions** in a chat interface

### Polish
- 🌙 Dark mode by default (brand palette `#101820` / `#F2AA4C`), optional light mode
- 🖱️ Hover effects and smooth animations on desktop/web
- 📱 Fully responsive: bottom navigation on mobile, navigation rail on tablet/desktop
- 📤 Share repository links, open anything on GitHub

---

## 🚀 Getting started

### Prerequisites
- [Flutter](https://docs.flutter.dev/get-started/install) **3.27 or newer** (Dart ≥ 3.3)

### Setup

```bash
git clone https://github.com/your-username/os-project-finder.git
cd os-project-finder

# 1. Generate the platform folders for the targets you want
flutter create . --platforms=web,android,windows,macos,linux

# 2. Install dependencies
flutter pub get

# 3. Generate Freezed / JSON models (required before first run)
dart run build_runner build --delete-conflicting-outputs

# 4. Run it
flutter run -d chrome     # web
flutter run -d windows    # or macos / linux
flutter run               # connected Android device/emulator
```

> Generated `*.freezed.dart` / `*.g.dart` files are intentionally gitignored — step 3 recreates them.

### API keys (both optional, both free)

| Key | Why | Where |
|---|---|---|
| **Gemini API key** | Enables all AI features | [aistudio.google.com/apikey](https://aistudio.google.com/apikey) → paste in **Settings** |
| **GitHub personal access token** | Raises the API rate limit from ~60/h to 5000/h and unlocks GraphQL contribution insights. No scopes needed. | GitHub → Settings → Developer settings → paste in **Settings** |

Keys are stored only on your device (local Hive storage) and sent only to Google / GitHub respectively.

> **Note on rate limits:** without a token, GitHub allows ~60 REST requests and 10 searches per minute per IP. The app surfaces a clear message when you hit the limit.

---

## 🏗️ Architecture

Clean, feature-first architecture — see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full tour.

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

**Stack:** Flutter · Riverpod · GoRouter · Dio · Freezed + json_serializable · Hive · flutter_markdown + flutter_highlight

---

## 🤝 Contributing

Contributions are very welcome — this app exists to help people contribute to open source, so it should be an easy first target itself! See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## 📄 License

[MIT](LICENSE)
