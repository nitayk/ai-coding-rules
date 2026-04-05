#!/usr/bin/env python3
import os
import yaml
import sys

def verify_file(filepath):
    # Skip symlinks whose targets don't exist (e.g. agents/commands -> .cursor/rules/shared)
    # Those targets are validated when the shared content is present
    if os.path.islink(filepath) and not os.path.exists(filepath):
        return True, None  # Skip broken symlinks, don't fail CI
    try:
        with open(filepath, 'r') as f:
            content = f.read()
    except Exception as e:
        return False, f"Could not read file: {e}"

    if not content.startswith('---'):
        # No frontmatter or not starting with ---
        return True, None

    try:
        # Extract frontmatter
        parts = content.split('---', 2)
        if len(parts) < 3:
            return False, "Malformed frontmatter (missing closing ---)"
        
        frontmatter = parts[1]
        yaml.safe_load(frontmatter)
        return True, None
    except yaml.YAMLError as exc:
        return False, str(exc)
    except Exception as e:
        return False, str(e)

def main():
    # If arguments are provided, check those files. Otherwise check all files in repo.
    if len(sys.argv) > 1:
        files_to_check = sys.argv[1:]
    else:
        # Walk from current directory
        files_to_check = []
        for dirpath, dirnames, filenames in os.walk('.'):
            # Skip .git and other hidden dirs
            if '/.' in dirpath:
                continue
            for filename in filenames:
                if filename.endswith('.md') or filename.endswith('.mdc'):
                    files_to_check.append(os.path.join(dirpath, filename))

    failed_files = []
    checked_count = 0

    for filepath in files_to_check:
        if not (filepath.endswith('.md') or filepath.endswith('.mdc')):
            continue
        checked_count += 1
        success, error = verify_file(filepath)
        if not success:
            failed_files.append((filepath, error))

    if failed_files:
        print(f"\n❌ Found {len(failed_files)} files with invalid YAML frontmatter:")
        for filepath, error in failed_files:
            print(f"- {filepath}: {error}")
        sys.exit(1)
    else:
        if checked_count > 0:
            print(f"✅ Checked {checked_count} files. All valid.")
        sys.exit(0)

if __name__ == "__main__":
    main()
