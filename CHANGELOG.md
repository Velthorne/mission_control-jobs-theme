## [Unreleased]

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
