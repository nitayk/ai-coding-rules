---
name: markitdown
description: "Convert local files (PDF, Word, Excel, PowerPoint, images/OCR, audio) to clean Markdown for efficient reading and ingestion. Use instead of reading the raw file directly when it is large, scanned, image-heavy, or a binary office document. Triggers on: markitdown, convert this pdf, convert this docx/pptx/xlsx, file to markdown, read this pdf/deck/spreadsheet, OCR this scan, transcribe this audio, extract markdown from file."
last-reviewed: 2026-06-10
---

# markitdown: Local File -> Markdown

[MarkItDown](https://github.com/microsoft/markitdown) (Microsoft, MIT) converts binary and office documents into clean Markdown for LLM ingestion: PDF, Word (`.docx`), Excel (`.xlsx`), PowerPoint (`.pptx`), images (with OCR), audio (with transcription), HTML, CSV, JSON, ZIP, and more.

Prefer this over reading the raw file directly whenever a non-text file would be lossy or token-expensive to read -- large PDFs, scanned/image PDFs, decks, and spreadsheets convert far more cleanly and cheaply through markitdown.

---

## Install

```bash
uv tool install 'markitdown[all]'
```

The `[all]` extra pulls in PDF, Office, image (OCR), and audio (transcription) support. Verify: `markitdown --version`

(If `uv` is not available: `pipx install 'markitdown[all]'` or `pip install 'markitdown[all]'`.)

---

## Usage

### Convert a file directly
```bash
markitdown path/to/report.pdf
```
Outputs Markdown to stdout.

### Save alongside the source
```bash
markitdown path/to/report.pdf > path/to/report.md
```

### Add a frontmatter header after saving
```bash
SLUG="report-$(date +%Y-%m-%d)"
{ echo "---"; echo "source_file: report.pdf"; echo "converted: $(date +%Y-%m-%d)"; echo "---"; echo ""; markitdown path/to/report.pdf; } > "path/to/$SLUG.md"
```

### Common formats
```bash
markitdown deck.pptx          # slides     -> markdown
markitdown sheet.xlsx         # tables     -> markdown
markitdown scan.png           # image      -> OCR text
markitdown talk.mp3           # audio      -> transcript
```

---

## When to Use

**Use markitdown when:**
- You need a PDF, `.docx`, `.pptx`, `.xlsx`, image, or audio file as clean markdown context
- The document is large, scanned, or image-heavy and reading it directly would be lossy or token-expensive
- You need OCR (scanned docs/images) or audio transcription

**Skip markitdown when:**
- The source is a URL -- fetch and clean it instead
- The source is already markdown or plain text
- markitdown is not installed and the file is a simple PDF the built-in file reader handles fine

---

## Fallback

```bash
which markitdown 2>/dev/null || echo "not installed"
```

If not installed: for plain PDFs, the built-in file reader can often read them directly. For Office / image / audio formats there is no clean fallback -- install markitdown (`uv tool install 'markitdown[all]'`).

---

## Privacy note

MarkItDown runs **locally** -- files are not uploaded anywhere. For sensitive or internal documents, prefer this over any cloud-backed document-conversion service.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
