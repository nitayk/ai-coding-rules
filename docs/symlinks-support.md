# Symlinks Support in Cursor

## Summary

Based on testing and documentation review:

✅ **Symlinks appear to work** for Skills, Agents, Commands, and Hooks in Cursor  
⚠️ **Not officially documented** - Cursor docs don't explicitly confirm symlink support  
✅ **Claude Code uses symlinks** - Similar setup uses symlinks successfully  
## Using Symlinks

Symlinks are the **default** behavior. The installer uses symlinks automatically:

```bash
# Default: Uses symlinks
bash .cursor/rules/shared/install.sh

# Use copying instead (fallback)
bash .cursor/rules/shared/install.sh --copy

# Combine with other options
bash .cursor/rules/shared/install.sh --dry-run --verbose
```

## Benefits of Symlinks

- ✅ **Faster setup** - No file copying
- ✅ **No duplication** - Single source of truth
- ✅ **Automatic updates** - Changes in submodule reflect immediately
- ✅ **Less disk space** - No duplicate files

## Drawbacks

- ⚠️ **Not officially documented** - May break in future Cursor versions
- ⚠️ **Requires testing** - Verify Cursor discovers symlinked files
- ⚠️ **Relative paths** - Symlinks use relative paths (can break if moved)

## Default Behavior

**Default: Symlinks** (faster, automatic updates)
- Files are symlinked to `.cursor/` directories
- Faster setup, automatic updates
- No need to run setup after submodule updates

**Optional: Copying** (fallback if symlinks don't work)
- Files are copied to `.cursor/` directories
- Use `--copy` flag if symlinks don't work in your Cursor version
- Requires running `install.sh` after submodule updates

## Verification

After using `--symlinks`, verify Cursor discovers the files:

1. Open Cursor Settings (Cmd+Shift+J / Ctrl+Shift+J)
2. Navigate to **Rules** tab
3. Check:
   - **Skills**: Should list all skills from `.cursor/skills/`
   - **Agents**: Should list all agents from `.cursor/agents/`
   - **Commands**: Should list all commands from `.cursor/commands/`
   - **Hooks**: Should show hooks.json loaded from `.cursor/hooks/`

If files are **not** discovered, Cursor doesn't support symlinks in your version - use default (copying).

## Recommendation

1. **Start with symlinks** (default) - Faster, automatic updates
2. **If symlinks don't work**, use `--copy` flag as fallback
3. **Verify** in Cursor Settings → Rules that files are discovered
4. **Monitor** Cursor updates - symlink support may change

## References

- [Cursor Skills Docs](https://cursor.com/docs/context/skills)
- [Cursor Hooks Docs](https://cursor.com/docs/agent/hooks)
- [Claude Code Setup](https://github.com/nitayk/ai-coding-rules) (uses symlinks)
