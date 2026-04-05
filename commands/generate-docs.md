# Generate Documentation

Generate or update documentation for recent changes.

## Usage

```
/docs [path-or-pattern]
```

## What it does

1. Analyzes recent changes (git diff or specified files)
2. Identifies what needs documentation:
   - New functions/classes
   - API changes
   - Configuration updates
   - Breaking changes
3. Generates documentation following project conventions:
   - JSDoc/TSDoc for code
   - README updates
   - API documentation
   - Migration guides for breaking changes
4. Updates existing docs or creates new files as needed

## Examples

```
/docs
```

Document all recent changes.

```
/docs src/api/
```

Document changes in the API directory.

```
/docs README.md
```

Update README based on recent changes.

## Documentation Types

- **Code Comments**: JSDoc, TSDoc, docstrings
- **README**: Usage examples, installation, getting started
- **API Docs**: Endpoints, parameters, responses
- **Migration Guides**: Breaking changes, upgrade paths
- **Architecture Docs**: High-level design decisions

## Best Practices

- Run after implementing features
- Use before creating PRs
- Follow existing documentation style
- Include examples for public APIs
