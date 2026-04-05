#!/usr/bin/env python3
"""
Fetch the plain-text content of a Google Doc.

Tries public export first; falls back to gcloud auth for private/org-restricted docs.

Usage:
    fetch_gdoc.py <google-doc-url-or-id>

Examples:
    fetch_gdoc.py https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms/edit
    fetch_gdoc.py 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms
"""

import re
import subprocess
import sys
import urllib.error
import urllib.request


def extract_doc_id(url_or_id: str) -> str:
    """Extract the document ID from a Google Docs URL or return as-is if already an ID."""
    match = re.search(r"/document/d/([a-zA-Z0-9_-]+)", url_or_id)
    if match:
        return match.group(1)
    if re.match(r"^[a-zA-Z0-9_-]+$", url_or_id.strip()):
        return url_or_id.strip()
    print(f"ERROR: Could not extract a Google Doc ID from: {url_or_id}", file=sys.stderr)
    sys.exit(1)


def fetch_public(doc_id: str) -> tuple[bool, str]:
    """Try fetching via the public export URL. Returns (success, content_or_error)."""
    export_url = f"https://docs.google.com/document/d/{doc_id}/export?format=txt"
    try:
        req = urllib.request.Request(export_url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            return True, resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        return False, f"HTTP {e.code}: {e.reason}"
    except Exception as e:
        return False, str(e)


def get_token(command: list[str]) -> tuple[bool, str]:
    """Run a gcloud command to get an access token. Returns (success, token_or_error)."""
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=10)
        if result.returncode != 0:
            return False, result.stderr.strip()
        token = result.stdout.strip()
        if not token:
            return False, "empty token returned"
        return True, token
    except FileNotFoundError:
        return False, "gcloud CLI not found"
    except Exception as e:
        return False, str(e)


def fetch_authenticated(doc_id: str, token: str) -> tuple[bool, str]:
    """Fetch via Drive API using an access token. Returns (success, content_or_error)."""
    export_url = (
        f"https://www.googleapis.com/drive/v3/files/{doc_id}/export"
        f"?mimeType=text%2Fplain"
    )
    try:
        req = urllib.request.Request(
            export_url, headers={"Authorization": f"Bearer {token}"}
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            return True, resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        return False, f"HTTP {e.code}: {e.reason}\n{body}"
    except Exception as e:
        return False, str(e)


def is_scope_error(error_msg: str) -> bool:
    return "insufficientPermissions" in error_msg or "PERMISSION_DENIED" in error_msg or "scope" in error_msg.lower()


def main():
    if len(sys.argv) != 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        sys.exit(0 if sys.argv[1:] in [["-h"], ["--help"]] else 1)

    doc_id = extract_doc_id(sys.argv[1])

    # 1. Try public access
    ok, result = fetch_public(doc_id)
    if ok:
        print(result)
        return

    print(f"[gdoc] Public fetch failed ({result}). Trying gcloud auth...", file=sys.stderr)

    # 2. Try each token source against the Drive API in turn
    token_sources = [
        (["gcloud", "auth", "print-access-token"], "user account"),
        (["gcloud", "auth", "application-default", "print-access-token"], "application-default"),
    ]
    last_error = None
    any_token = False

    for cmd, label in token_sources:
        ok, val = get_token(cmd)
        if not ok:
            print(f"[gdoc] gcloud {label} token unavailable: {val}", file=sys.stderr)
            continue
        any_token = True
        print(f"[gdoc] Trying Drive API with {label} token...", file=sys.stderr)
        ok, result = fetch_authenticated(doc_id, val)
        if ok:
            print(result)
            return
        last_error = (label, result)
        if not is_scope_error(result):
            # Non-scope error (e.g. 404, access denied) — no point trying other tokens
            break

    if not any_token:
        print(
            "ERROR: Could not obtain a gcloud access token.\n\n"
            "To fix this, run:\n"
            "  gcloud auth login --enable-gdrive-access\n\n"
            "Then make sure the document is shared with your Google account.",
            file=sys.stderr,
        )
        sys.exit(1)

    label, result = last_error
    if is_scope_error(result):
        print(
            "ERROR: All available gcloud tokens lack Drive API scopes.\n\n"
            "To fix this, run ONE of:\n"
            "  gcloud auth login --enable-gdrive-access\n"
            "  gcloud auth application-default login --scopes=https://www.googleapis.com/auth/drive.readonly,https://www.googleapis.com/auth/cloud-platform\n\n"
            "Then retry.",
            file=sys.stderr,
        )
    else:
        print(
            f"ERROR: Authenticated fetch failed ({label}): {result}\n\n"
            "Make sure:\n"
            "  1. The document is shared with your Google account\n"
            "  2. Your gcloud account is logged in: gcloud auth login\n"
            "  3. The document ID is correct",
            file=sys.stderr,
        )
    sys.exit(1)


if __name__ == "__main__":
    main()
