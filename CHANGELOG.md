## [0.4.0] - 2026-04-19

- Migrate theme assets from `Rack::Static` to the Rails asset pipeline (adds sub-URI deployment support, fixes stale assets after gem upgrade)
- Move theme injection off the host app's middleware stack (with mount-path matching) and into `MissionControl::Jobs::Engine` middleware
  - **Breaking:** `config.mount_path` has been removed. Delete it from your initializer — Rails routing now determines when the middleware runs.
- Automate assets minification via a `rake assets:minify` task (using esbuild)
- Drop Sprockets support and require Propshaft — needed to fingerprint the bundled font URLs in CSS assets

## [0.3.2] - 2026-04-18

- Automatic CSP nonce support for injected script tags

## [0.3.1] - 2026-04-17

- Visual refinements across both themes for improved consistency and accessibility

## [0.3.0] - 2026-04-16

- Dark mode support with auto color scheme that follows OS preference
- Navbar color scheme switcher with cookie-based persistence across sessions

## [0.2.0] - 2026-03-31

- Broaden compatibility to Ruby >= 3.2 and Rails >= 7.1 (previously Ruby 3.4 / Rails 8.1 only)

## [0.1.4] - 2026-03-29

- Refined visual styling across all components for a softer, more polished look

## [0.1.3] - 2026-03-22

- Fix incorrect gem root path calculation; use `Gem.loaded_specs` instead of relative path traversal

## [0.1.2] - 2026-03-22

- Fix `prism-init.js` 404 caused by overlapping `Rack::Static` URL prefixes across two roots
- Consolidate all assets under `assets/`; remove `vendor/` directory

## [0.1.1] - 2026-03-22

- README improvements, gemspec metadata fixes, and packaging cleanup

## [0.1.0] - 2026-03-20

- Malachite Light CSS theme for MissionControl::Jobs UI with custom fonts (Archivo Narrow, Albert Sans)
- PrismJS JSON syntax highlighting on job detail pages
- Automatic mount path discovery via Rails route inspection
- Rails generator for optional initializer (`bin/rails generate mission_control:jobs:theme:install`)
