#!/usr/bin/env python3
"""
Write to a Google Doc: add tabs, append or replace content.

Usage:
    write_gdoc.py <url-or-id> list-tabs
    write_gdoc.py <url-or-id> add-tab <tab-name>
    write_gdoc.py <url-or-id> append <tab-name-or-id> <text>
    write_gdoc.py <url-or-id> append <tab-name-or-id> --file <path>
    write_gdoc.py <url-or-id> replace <tab-name-or-id> <text>
    write_gdoc.py <url-or-id> replace <tab-name-or-id> --file <path>
    write_gdoc.py <url-or-id> delete-tab <tab-name-or-id>

Examples:
    write_gdoc.py https://docs.google.com/document/d/DOC_ID/edit list-tabs
    write_gdoc.py DOC_ID add-tab "Sprint Notes"
    write_gdoc.py DOC_ID append "Sprint Notes" "- Completed auth refactor"
    write_gdoc.py DOC_ID replace "Sprint Notes" --file notes.txt
    write_gdoc.py DOC_ID delete-tab "hechen-test"

Tab resolution: <tab-name-or-id> matches by tab title (case-insensitive) or exact tab ID.
"""

import json
import re
import subprocess
import sys
import urllib.error
import urllib.request


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------

def get_token() -> str:
    """Return a gcloud access token, trying user account then application-default."""
    for cmd in [
        ["gcloud", "auth", "print-access-token"],
        ["gcloud", "auth", "application-default", "print-access-token"],
    ]:
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
        except FileNotFoundError:
            print("ERROR: gcloud CLI not found. Install from https://cloud.google.com/sdk", file=sys.stderr)
            sys.exit(1)
    print(
        "ERROR: Could not get a gcloud access token.\n\n"
        "Run: gcloud auth login --enable-gdrive-access",
        file=sys.stderr,
    )
    sys.exit(1)


# ---------------------------------------------------------------------------
# API helpers
# ---------------------------------------------------------------------------

BASE = "https://docs.googleapis.com/v1/documents"


def api_get(doc_id: str, token: str, params: str = "") -> dict:
    req = urllib.request.Request(
        f"{BASE}/{doc_id}{params}",
        headers={"Authorization": f"Bearer {token}"},
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        _die_http(e)


def api_batch(doc_id: str, token: str, requests: list) -> dict:
    body = json.dumps({"requests": requests}).encode()
    req = urllib.request.Request(
        f"{BASE}/{doc_id}:batchUpdate",
        data=body,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        _die_http(e)


def _die_http(e: urllib.error.HTTPError):
    body = e.read().decode("utf-8", errors="replace")
    if "insufficientPermissions" in body or "PERMISSION_DENIED" in body:
        print(
            f"ERROR: HTTP {e.code} — insufficient permissions.\n\n"
            "Run: gcloud auth login --enable-gdrive-access\n"
            "Then retry.",
            file=sys.stderr,
        )
    else:
        print(f"ERROR: HTTP {e.code}: {e.reason}\n{body}", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# Tab helpers
# ---------------------------------------------------------------------------

def extract_doc_id(url_or_id: str) -> str:
    match = re.search(r"/document/d/([a-zA-Z0-9_-]+)", url_or_id)
    if match:
        return match.group(1)
    if re.match(r"^[a-zA-Z0-9_-]+$", url_or_id.strip()):
        return url_or_id.strip()
    print(f"ERROR: Could not extract a Google Doc ID from: {url_or_id}", file=sys.stderr)
    sys.exit(1)


def get_tabs(doc_id: str, token: str) -> list[dict]:
    """Return list of tab dicts with tabProperties and documentTab."""
    doc = api_get(doc_id, token, "?includeTabsContent=true")
    return doc.get("tabs", [])


def resolve_tab(tabs: list[dict], name_or_id: str) -> dict:
    """Find a tab by title (case-insensitive) or tab ID. Exit if not found."""
    needle = name_or_id.strip().lower()
    for t in tabs:
        props = t["tabProperties"]
        if props["tabId"].lower() == needle or props["title"].lower() == needle:
            return t
    available = ", ".join(f'"{t["tabProperties"]["title"]}"' for t in tabs)
    print(f'ERROR: Tab "{name_or_id}" not found. Available: {available}', file=sys.stderr)
    sys.exit(1)


def tab_body_end_index(tab: dict) -> int:
    """Return the end index of the tab body (exclusive of the final newline sentinel)."""
    content = tab.get("documentTab", {}).get("body", {}).get("content", [])
    if not content:
        return 1
    last = content[-1]
    end = last.get("endIndex", 1)
    return end


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_list_tabs(doc_id: str, token: str):
    tabs = get_tabs(doc_id, token)
    print(f"{'#':<4} {'Title':<30} {'Tab ID'}")
    print("-" * 55)
    for t in tabs:
        p = t["tabProperties"]
        print(f"{p['index']:<4} {p['title']:<30} {p['tabId']}")


def cmd_add_tab(doc_id: str, token: str, name: str):
    resp = api_batch(doc_id, token, [
        {"addDocumentTab": {"tabProperties": {"title": name}}}
    ])
    props = resp["replies"][0]["addDocumentTab"]["tabProperties"]
    print(f"Created tab \"{props['title']}\" (id={props['tabId']}, index={props['index']})")


def cmd_append(doc_id: str, token: str, tab_ref: str, text: str):
    tabs = get_tabs(doc_id, token)
    tab = resolve_tab(tabs, tab_ref)
    tab_id = tab["tabProperties"]["tabId"]
    end = tab_body_end_index(tab)
    # Insert before the final sentinel character (end - 1)
    insert_index = max(1, end - 1)
    api_batch(doc_id, token, [{
        "insertText": {
            "location": {"index": insert_index, "tabId": tab_id},
            "text": text if text.endswith("\n") else text + "\n",
        }
    }])
    print(f"Appended {len(text)} chars to tab \"{tab['tabProperties']['title']}\".")


def cmd_replace(doc_id: str, token: str, tab_ref: str, text: str):
    tabs = get_tabs(doc_id, token)
    tab = resolve_tab(tabs, tab_ref)
    tab_id = tab["tabProperties"]["tabId"]
    end = tab_body_end_index(tab)

    requests = []
    # Delete existing content if there is any (indices 1 to end-1)
    if end > 2:
        requests.append({
            "deleteContentRange": {
                "range": {"startIndex": 1, "endIndex": end - 1, "tabId": tab_id}
            }
        })
    # Insert new content
    requests.append({
        "insertText": {
            "location": {"index": 1, "tabId": tab_id},
            "text": text if text.endswith("\n") else text + "\n",
        }
    })
    api_batch(doc_id, token, requests)
    print(f"Replaced content of tab \"{tab['tabProperties']['title']}\" ({len(text)} chars).")


def cmd_delete_tab(doc_id: str, token: str, tab_ref: str):
    tabs = get_tabs(doc_id, token)
    tab = resolve_tab(tabs, tab_ref)
    tab_id = tab["tabProperties"]["tabId"]
    title = tab["tabProperties"]["title"]
    api_batch(doc_id, token, [{"deleteTab": {"tabId": tab_id}}])
    print(f"Deleted tab \"{title}\" (id={tab_id}).")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def usage():
    print(__doc__.strip())
    sys.exit(1)


def main():
    args = sys.argv[1:]
    if len(args) < 2 or args[0] in ("-h", "--help"):
        usage()

    doc_id = extract_doc_id(args[0])
    cmd = args[1]
    token = get_token()

    if cmd == "list-tabs":
        cmd_list_tabs(doc_id, token)

    elif cmd == "add-tab":
        if len(args) < 3:
            print("Usage: write_gdoc.py <doc> add-tab <tab-name>", file=sys.stderr)
            sys.exit(1)
        cmd_add_tab(doc_id, token, args[2])

    elif cmd in ("append", "replace"):
        if len(args) < 4:
            print("Usage: write_gdoc.py <doc> {append|replace} <tab> <text|--file path>", file=sys.stderr)
            sys.exit(1)
        tab_ref = args[2]
        if args[3] == "--file":
            if len(args) < 5:
                print("ERROR: --file requires a path argument", file=sys.stderr)
                sys.exit(1)
            text = open(args[4]).read()
        else:
            text = " ".join(args[3:])
        fn = cmd_append if cmd == "append" else cmd_replace
        fn(doc_id, token, tab_ref, text)

    elif cmd == "delete-tab":
        if len(args) < 3:
            print("Usage: write_gdoc.py <doc> delete-tab <tab-name-or-id>", file=sys.stderr)
            sys.exit(1)
        cmd_delete_tab(doc_id, token, args[2])

    else:
        print(f"ERROR: Unknown command '{cmd}'", file=sys.stderr)
        usage()


if __name__ == "__main__":
    main()
