# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-07

### Added
- **Android Platform Support**: Added complete Android project configuration (`android/`) with target SDK 34, location permissions, and namespace `com.helltrilla.maps`.
- **Feature-First Clean Architecture**: Restructured codebase into `lib/core` (constants, config, errors, theme, network) and `lib/features` (`map`, `markers`, `places`, `routing`, `search`) with decoupled data, domain, and presentation layers.
- **Riverpod State Management**: Integrated `flutter_riverpod` (`ProviderScope`, `StateNotifierProvider`) to remove business logic and state synchronization from UI widgets.
- **Configurable Service Endpoints (`AppConfig`)**: Centralized tile URLs, OSRM router, Overpass API mirrors, and Photon/Nominatim endpoints with `--dart-define` override support for self-hosted deployments.
- **Interactive Map Attribution**: Added visible on-screen attribution widget (`MapAttributionWidget`) complying with OpenStreetMap tile usage policies and layer copyright requirements.
- **Comprehensive Test Suite**:
  - Unit tests for OSRM, Overpass, and Photon data sources with mocked HTTP responses (`MockClient`).
  - Failover tests verifying automatic mirror switching during HTTP 504 timeouts and service degradations.
  - SharedPreferences persistence tests including migration from legacy storage formats.
  - Widget tests for map attribution dialog, search bar, place details bottom sheet, and route planner.
- **Continuous Integration Pipeline**: Configured GitHub Actions workflow (`.github/workflows/ci.yml`) enforcing code formatting, strict static analysis, and test coverage on all pushes and pull requests.
- **Documentation**:
  - Added comprehensive provider limits, terms of use, and self-hosting guide in `docs/PROVIDERS_AND_LICENSES.md`.
  - Added English primary documentation (`README.md`) and Russian counterpart (`README.ru.md`).

### Changed
- **Decomposed Monolith**: Modularized 1,200+ line `main_screen.dart` into specialized widgets and state controllers under 400 lines each.
- **Strict Linting**: Configured strict static analyzer options in `analysis_options.yaml` (`strict-casts`, `strict-inference`, `strict-raw-types`, and 35+ additional rules) with zero analyzer warnings.
- **Search Robustness**: Implemented request cancellation and token tracking in search to eliminate asynchronous race conditions.
- **Demo Fixture Transparency**: Explicitly labeled place reviews and photo generation as demonstration mock fixtures across UI and documentation.
- **Asset Optimization**: Relocated screenshots from bundled `assets/` to `docs/screenshots/` to prevent unnecessary app binary bloat.

### Fixed
- Fixed gray/missing tile loading issues at zoom levels above 19 by introducing `maxNativeZoom: 19` overzoom interpolation up to zoom 22.
- Fixed ListTile ink splash rendering warnings inside decorated glassmorphic search panels.
- Fixed outdated bundle identifiers to consistently use `com.helltrilla.maps`.
