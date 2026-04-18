# MissionControl::Jobs::Theme

[![CI](https://github.com/Velthorne/mission_control-jobs-theme/actions/workflows/main.yml/badge.svg)](https://github.com/Velthorne/mission_control-jobs-theme/actions/workflows/main.yml)
[![Gem Version](https://badge.fury.io/rb/mission_control-jobs-theme.svg)](https://badge.fury.io/rb/mission_control-jobs-theme)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

A drop-in visual theme for [MissionControl::Jobs](https://github.com/rails/mission_control-jobs) — malachite color palette with light/dark mode, refined typography, and JSON syntax highlighting. No view overrides — Rack middleware injects theme files before `</head>`, so upstream view changes don't break the theme.

## Screenshots

### Jobs list

| Light                                                                                                                            | Dark                                                                                                                            |
|----------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| ![](https://raw.githubusercontent.com/Velthorne/mission_control-jobs-theme/refs/heads/main/docs/screenshots/light-jobs-list.png) | ![](https://raw.githubusercontent.com/Velthorne/mission_control-jobs-theme/refs/heads/main/docs/screenshots/dark-jobs-list.png) |

### Job details

| Light                                                                                                                           | Dark                                                                                                                           |
|---------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|
| ![](https://raw.githubusercontent.com/Velthorne/mission_control-jobs-theme/refs/heads/main/docs/screenshots/light-job-page.png) | ![](https://raw.githubusercontent.com/Velthorne/mission_control-jobs-theme/refs/heads/main/docs/screenshots/dark-job-page.png) |

### Worker overview

| Light                                                                                                                              | Dark                                                                                                                              |
|------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| ![](https://raw.githubusercontent.com/Velthorne/mission_control-jobs-theme/refs/heads/main/docs/screenshots/light-worker-page.png) | ![](https://raw.githubusercontent.com/Velthorne/mission_control-jobs-theme/refs/heads/main/docs/screenshots/dark-worker-page.png) |

## Requirements

- Ruby **>= 3.2**
- Rails **>= 7.1**
- [mission_control-jobs](https://github.com/rails/mission_control-jobs) **>= 1.1**
- Propshaft

## Installation

Add to your Gemfile:

```ruby
gem "mission_control-jobs-theme"
```

Then run:

```bash
bundle install
```

That's it — the theme activates automatically, no configuration is required.

## How it works

Theme CSS, JS, and fonts are served through the host app's Propshaft load path. A Rack middleware intercepts HTML responses from `MissionControl::Jobs::Engine` and injects the asset links, a color scheme switcher, and optional [PrismJS](https://prismjs.com) syntax highlighting before `</head>` — with CSP nonces applied to `<script>` tags when available.

## Configuration

To customize the defaults, generate an initializer:

```bash
bin/rails generate mission_control:jobs:theme:install
```

This creates `config/initializers/mission_control_jobs_theme.rb`:

```ruby
MissionControl::Jobs::Theme.configure do |config|
  # config.color_scheme = :auto          # :auto, :light, :dark
  # config.color_scheme_switcher = true  # show navbar toggle
  # config.syntax_highlighting = true    # PrismJS on job detail
  # config.theme = :malachite            # available: :malachite
end
```

| Option                   | Default                 | Description                                                                                                                                                                |
|--------------------------|-------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `color_scheme`           | `:auto`                 | Light/dark appearance. `:auto` follows the OS preference via `prefers-color-scheme`; `:light` or `:dark` forces one.                                                       |
| `color_scheme_switcher`  | `true`                  | Show a light/dark/auto toggle in the navbar. When `false`, the scheme is locked to the configured default.                                                                 |
| `syntax_highlighting`    | `true`                  | Enable PrismJS JSON syntax highlighting on job detail pages. Set to `false` to inject only the CSS theme.                                                                  |
| `theme`                  | `:malachite`            | Visual theme family. Each family provides both light and dark variants.                                                                                                    |

## Compatibility

- Designed for **MissionControl::Jobs 1.1+** which uses Bulma for its UI. The theme overrides Bulma variables and component styles, so it stays functional even if upstream markup changes.
- Requires **Propshaft**. Theme assets ship through the host app's asset pipeline with fingerprinted URLs. Sprockets is not supported because its `url()` rewriting does not apply to plain `.css`, so `@font-face` paths would not be fingerprinted.
- Tested with **Solid Queue**. **Resque** works but may have unstyled areas in adapter-specific views.

## Troubleshooting

If the theme doesn't appear:

1. Ensure `mission_control-jobs` is in your `Gemfile` and the engine is mounted in `config/routes.rb`:
   ```ruby
   mount MissionControl::Jobs::Engine, at: "/jobs"
   ```
2. Verify the middleware is attached to the engine's own stack:
   ```ruby
   MissionControl::Jobs::Engine.app # force the stack to build if no request has been served yet
   MissionControl::Jobs::Engine.middleware.middlewares.map(&:klass)
   ```
   The list should include `MissionControl::Jobs::Theme::Middleware`. (The middleware runs on the engine stack, not the host app stack, so it does not appear in `bin/rails middleware` output.)

## Contributing

Contributions of any kind are appreciated — whether it's a bug report, feature idea, or pull request. Feel free to open an [issue](https://github.com/Velthorne/mission_control-jobs-theme/issues) or submit a [PR](https://github.com/Velthorne/mission_control-jobs-theme/pulls).

```bash
bin/setup                 # Install dependencies
bundle exec rspec         # Run the test suite
bundle exec rubocop       # Run the linter
bin/console               # Interactive prompt
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

### Third-party assets

The gem bundles:

- [Albert Sans](https://fonts.google.com/specimen/Albert+Sans) — SIL Open Font License 1.1 (`vendor/assets/fonts/mission_control/theme/Albert_Sans/OFL.txt`)
- [Archivo Narrow](https://fonts.google.com/specimen/Archivo+Narrow) — SIL Open Font License 1.1 (`vendor/assets/fonts/mission_control/theme/Archivo_Narrow/OFL.txt`)
- [PrismJS](https://prismjs.com) — MIT License
