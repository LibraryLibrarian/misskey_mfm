# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-01-23

### Changed
- **BREAKING**: Minimum Dart SDK version raised to `^3.8.0` (from `^3.0.0`)
- **BREAKING**: All AST classes migrated to freezed sealed class union pattern
- **BREAKING**: Added `freezed_annotation: ^3.1.0` as a runtime dependency

### Added
- Value equality (`==` and `hashCode`) for all MfmNode types
- `copyWith()` method for immutable updates on all nodes
- Enhanced `toString()` output for debugging
- Dart 3 pattern matching support with exhaustiveness checking

### Removed
- `custom_lint` dev dependency (incompatible with newer analyzer version)

## [1.0.0] - 2026-01-21

### Added
- I rewrote the parsing process from scratch using Dart and petitparser, based on mfm-js.  
At this stage, the basic parsing functionality is complete.  
I plan to create the rendering process using a different library in the future.

## [1.0.1] - 2026-01-21

The reason for the PUB POINTS being 150 on pub.dev was due to exceeding the 180-character limit in the description.  
I shortened part of the explanation to fit within the base character count. There are no changes to the library's functionality with this update.