# Generate Changelog

Generate a changelog from recent commits following Keep a Changelog format.

## Usage

```
/changelog [from-tag] [to-tag]
/changelog
```

## What it does

1. Fetches commit history between tags (or since last tag if no tags provided)
2. Groups commits by conventional commit type:
   - **Added** (feat:) - New features
   - **Fixed** (fix:) - Bug fixes
   - **Changed** (BREAKING CHANGE:) - Breaking changes
   - **Documentation** (docs:) - Documentation updates
   - **Refactoring** (refactor:) - Code refactoring
   - **Performance** (perf:) - Performance improvements
   - **Tests** (test:) - Test additions/changes
   - **Chore** (chore:) - Maintenance tasks
3. Formats output following [Keep a Changelog](https://keepachangelog.com/) conventions
4. Appends to existing CHANGELOG.md or creates new one
5. Includes date and version information

## Examples

```
/changelog
```

Generate changelog since last tag.

```
/changelog v1.2.0 v1.3.0
```

Generate changelog between specific versions.

## Format

Follows [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
## [1.3.0] - 2026-01-25

### Added
- New feature X
- New feature Y

### Fixed
- Bug fix A
- Bug fix B

### Changed
- Breaking change description
```

## Requirements

- Uses conventional commit messages (feat:, fix:, etc.)
- Requires git tags for version ranges
