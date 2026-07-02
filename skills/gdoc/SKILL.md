---
name: gdoc
description: Use when user wants to Read and write Google Docs from a URL. Use this skill whenever the user provides a Google Docs URL (docs.google.com/document/...) to read requirements, specs, or briefs, OR to write back to the doc—such as adding a new tab, appending notes, or replacing tab content. Handles both public and private/org-restricted documents automatically via gcloud auth. Do NOT use for Word files, PDFs, spreadsheets as primary deliverable, or tasks with no Google Doc URL.
disable-model-invocation: true
last-reviewed: 2026-05-27
---

# Google Doc Reader & Writer

Read from and write to Google Docs directly from the conversation.

## Tool selection

**Prefer the `google-workspace` MCP when available** (tools prefixed `mcp__google-workspace__*`). It handles auth, tabs, and formatting natively — no script bundling, no gcloud setup per machine. Fall back to the bundled gcloud-auth Python scripts only when the MCP isn't configured in this workspace.

Quick check: if `mcp__google-workspace__readGoogleDoc` appears in your tool list, use the MCP. Otherwise use the scripts (see below).

## Option A — google-workspace MCP (preferred)

| Action | Tool |
|---|---|
| Read doc content (all tabs) | `mcp__google-workspace__readGoogleDoc` |
| List / search docs | `mcp__google-workspace__listGoogleDocs`, `mcp__google-workspace__searchGoogleDocs` |
| Get doc metadata + tab list | `mcp__google-workspace__getDocumentInfo`, `mcp__google-workspace__listDocumentTabs` |
| Append text to end | `mcp__google-workspace__appendToGoogleDoc` |
| Targeted edits (insert / replace / style) | `mcp__google-workspace__editGoogleDoc`, `mcp__google-workspace__insertText`, `mcp__google-workspace__formatMatchingText` |
| Create a new doc | `mcp__google-workspace__createDocument` |

Pass the Google Doc URL or fileId. First call may prompt `mcp__google-workspace__addAccount` if no account is wired up — use `mcp__google-workspace__listAccounts` to check.

## Option B — bundled gcloud scripts (fallback)

Use only when the MCP isn't available. Path may be `skills/gdoc/scripts/` or `.cursor/skills/gdoc/scripts/` depending on workspace setup.

**Read:**
```bash
python3 skills/gdoc/scripts/fetch_gdoc.py "<google-doc-url>"
```
Outputs full plain-text content of the doc (all tabs).

**Write (`write_gdoc.py`):** tab names are matched case-insensitively.

```bash
# list tabs
python3 skills/gdoc/scripts/write_gdoc.py "<url>" list-tabs

# add a new tab
python3 skills/gdoc/scripts/write_gdoc.py "<url>" add-tab "Tab Name"

# append to end of tab content
python3 skills/gdoc/scripts/write_gdoc.py "<url>" append "Tab Name" "text"
python3 skills/gdoc/scripts/write_gdoc.py "<url>" append "Tab Name" --file out.txt

# replace tab content (clear + rewrite)
python3 skills/gdoc/scripts/write_gdoc.py "<url>" replace "Tab Name" "new content"
python3 skills/gdoc/scripts/write_gdoc.py "<url>" replace "Tab Name" --file out.txt

# delete tab
python3 skills/gdoc/scripts/write_gdoc.py "<url>" delete-tab "Tab Name"
```

**Auth (scripts only):** both scripts try `gcloud auth print-access-token` then `gcloud auth application-default print-access-token`. One-time setup for private/org docs:

```bash
gcloud auth login --enable-gdrive-access
```

After that, any doc shared with your Google account works automatically.

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
