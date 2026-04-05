# Updating This Content

This directory is a snapshot from [github.com/anthropics/skills](https://github.com/anthropics/skills.git).

## Important

**DO NOT manually edit files in this directory.** Manual edits will be overwritten when content is updated from upstream.

## How to Update

Run the community update script from the repo root:

```bash
python -m scripts.update_community
```

A GitHub Actions workflow runs weekly to check for updates and create a PR.
