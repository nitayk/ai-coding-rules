---
name: gdoc
description: Use when user wants to Read and write Google Docs from a URL. Use this skill whenever the user provides a Google Docs URL (docs.google.com/document/...) to read requirements, specs, or briefs, OR to write back to the doc—such as adding a new tab, appending notes, or replacing tab content. Handles both public and private/org-restricted documents automatically via gcloud auth. Do NOT use for Word files, PDFs, spreadsheets as primary deliverable, or tasks with no Google Doc URL.
disable-model-invocation: true
---

# Google Doc Reader & Writer

Read from and write to Google Docs directly from the conversation.

## Reading a Doc

Run the fetch script with the Google Doc URL. Path may be `skills/gdoc/scripts/` or `.cursor/skills/gdoc/scripts/` depending on workspace setup:

```bash
python3 skills/gdoc/scripts/fetch_gdoc.py "<google-doc-url>"
# Or if synced to .cursor: python3 .cursor/skills/gdoc/scripts/fetch_gdoc.py "<url>"
```

Output is the full plain-text content of the doc (all tabs). Use it as context for the current task.

## Writing to a Doc

Use `write_gdoc.py` for all write operations. Tab names are matched case-insensitively.

**List tabs:**
```bash
python3 skills/gdoc/scripts/write_gdoc.py "<url>" list-tabs
```

**Add a new tab:**
```bash
python3 skills/gdoc/scripts/write_gdoc.py "<url>" add-tab "Tab Name"
```

**Append text to a tab** (adds to end of existing content):
```bash
python3 skills/gdoc/scripts/write_gdoc.py "<url>" append "Tab Name" "text to add"
python3 skills/gdoc/scripts/write_gdoc.py "<url>" append "Tab Name" --file output.txt
```

**Replace a tab's content** (clears and rewrites):
```bash
python3 skills/gdoc/scripts/write_gdoc.py "<url>" replace "Tab Name" "new content"
python3 skills/gdoc/scripts/write_gdoc.py "<url>" replace "Tab Name" --file output.txt
```

**Delete a tab:**
```bash
python3 skills/gdoc/scripts/write_gdoc.py "<url>" delete-tab "Tab Name"
```

## Auth

Both scripts try gcloud tokens in this order:
1. `gcloud auth print-access-token` (user account)
2. `gcloud auth application-default print-access-token`

**One-time setup for private/org docs:**
```bash
gcloud auth login --enable-gdrive-access
```

After that, any doc shared with your Google account works automatically — no extra steps when pasting a link.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
