#!/bin/bash
# worktree-manager.sh - Manage git worktrees safely and efficiently
# Usage: ./worktree-manager.sh [create|list|remove] [args...]

set -e

COMMAND=$1
shift

PROJECT_ROOT=$(git rev-parse --show-toplevel)
PROJECT_NAME=$(basename "$PROJECT_ROOT")
GLOBAL_WORKTREE_DIR="$HOME/.config/superpowers/worktrees/$PROJECT_NAME"
LOCAL_WORKTREE_DIR=".worktrees"

# Detect preferred location
detect_location() {
    if [ -d "$LOCAL_WORKTREE_DIR" ]; then
        echo "$LOCAL_WORKTREE_DIR"
    elif [ -d "worktrees" ]; then
        echo "worktrees"
    elif [ -d "$GLOBAL_WORKTREE_DIR" ]; then
        echo "$GLOBAL_WORKTREE_DIR"
    else
        # Default to local hidden dir if nothing exists
        echo "$LOCAL_WORKTREE_DIR"
    fi
}

verify_ignore() {
    local dir=$1
    # Only verify for local directories
    if [[ "$dir" == .* ]] || [[ "$dir" == "worktrees" ]]; then
        if ! git check-ignore -q "$dir"; then
            echo "⚠️  Warning: $dir is NOT ignored by git."
            echo "Adding to .gitignore..."
            echo "$dir/" >> .gitignore
            git add .gitignore
            git commit -m "chore: ignore worktree directory $dir"
            echo "✅ Added $dir to .gitignore and committed."
        fi
    fi
}

create_worktree() {
    local branch=$1
    if [ -z "$branch" ]; then
        echo "Usage: $0 create <branch-name>"
        exit 1
    fi

    local location=$(detect_location)
    local path="$location/$branch"

    echo "🔍 Location: $location"
    verify_ignore "$location"

    echo "🚀 Creating worktree for branch '$branch' at '$path'..."
    git worktree add -b "$branch" "$path" master 2>/dev/null || git worktree add -b "$branch" "$path" main

    echo "📦 Running setup in $path..."
    cd "$path"

    # Auto-setup
    if [ -f package.json ]; then npm install; fi
    if [ -f Cargo.toml ]; then cargo build; fi
    if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
    if [ -f go.mod ]; then go mod download; fi
    if [ -f build.sbt ]; then sbt update; fi

    echo "✅ Worktree ready at $path"
    echo "To enter: cd $path"
}

list_worktrees() {
    git worktree list
}

remove_worktree() {
    local path=$1
    if [ -z "$path" ]; then
        echo "Usage: $0 remove <path>"
        exit 1
    fi
    git worktree remove "$path"
    echo "✅ Removed worktree at $path"
}

case "$COMMAND" in
    create)
        create_worktree "$@"
        ;;
    list)
        list_worktrees
        ;;
    remove)
        remove_worktree "$@"
        ;;
    *)
        echo "Usage: $0 {create|list|remove}"
        exit 1
        ;;
esac
