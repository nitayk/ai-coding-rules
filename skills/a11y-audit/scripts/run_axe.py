#!/usr/bin/env python3
"""
a11y-audit: thin axe-core runner over Playwright.

Loads a URL (or local file), injects axe-core, runs the WCAG ruleset, and prints
a violation report grouped by impact severity (critical > serious > moderate > minor),
with the rule id, help text, help URL, and the offending element selectors/snippets.

This is a BLACK-BOX runner — call it, read its stdout. Do NOT read this source into
context unless you need to customize it. For the Playwright mechanics this mirrors the
`webapp-testing` skill (native sync Playwright).

Usage:
    python run_axe.py --help
    python run_axe.py --url http://localhost:5173
    python run_axe.py --url http://localhost:5173 --tags wcag2a,wcag2aa,wcag21aa
    python run_axe.py --url http://localhost:5173 --json out.json
    python run_axe.py --file ./dist/index.html

Requirements (install if missing):
    pip install playwright
    playwright install chromium
axe-core is fetched from a CDN at runtime; pass --axe-path to inject a local copy
(e.g. node_modules/axe-core/axe.min.js) for offline/air-gapped runs.

Exit code: 0 if no violations, 1 if any violation found, 2 on runtime error.
"""
import argparse
import json
import sys
from pathlib import Path

AXE_CDN = "https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.10.2/axe.min.js"
IMPACT_ORDER = ["critical", "serious", "moderate", "minor", None]


def build_axe_options(tags):
    if not tags:
        return "{}"
    tag_list = [t.strip() for t in tags.split(",") if t.strip()]
    return json.dumps({"runOnly": {"type": "tag", "values": tag_list}})


def run(url, axe_source, axe_options_json, reduced_motion):
    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        browser = p.chromium.launch()
        context = browser.new_context(
            reduced_motion="reduce" if reduced_motion else "no-preference"
        )
        page = context.new_page()
        page.goto(url, wait_until="networkidle")
        page.add_script_tag(content=axe_source)
        result = page.evaluate(
            "async (opts) => await window.axe.run(document, opts)",
            json.loads(axe_options_json),
        )
        browser.close()
        return result


def load_axe(axe_path):
    if axe_path:
        return Path(axe_path).read_text()
    # fetch from CDN via urllib (no extra deps)
    import urllib.request

    with urllib.request.urlopen(AXE_CDN, timeout=30) as r:
        return r.read().decode("utf-8")


def render_report(result):
    violations = result.get("violations", [])
    if not violations:
        print("PASS — axe-core found 0 violations.")
        return 0

    by_impact = {}
    for v in violations:
        by_impact.setdefault(v.get("impact"), []).append(v)

    total_nodes = sum(len(v["nodes"]) for v in violations)
    print(f"FAIL — {len(violations)} rule violations across {total_nodes} elements.\n")

    for impact in IMPACT_ORDER:
        group = by_impact.get(impact)
        if not group:
            continue
        label = (impact or "unknown").upper()
        print(f"==== {label} ({len(group)} rules) ====")
        for v in group:
            print(f"\n  [{v['id']}] {v['help']}")
            print(f"    WCAG/Help: {v['helpUrl']}")
            print(f"    Affected elements: {len(v['nodes'])}")
            for node in v["nodes"][:5]:
                sel = " > ".join(
                    s if isinstance(s, str) else " ".join(s) for s in node["target"]
                )
                snippet = node.get("html", "").strip()[:120]
                print(f"      - {sel}")
                if snippet:
                    print(f"        {snippet}")
                fix = node.get("failureSummary", "").replace("\n", " ").strip()
                if fix:
                    print(f"        Fix: {fix[:200]}")
            if len(v["nodes"]) > 5:
                print(f"      ... and {len(v['nodes']) - 5} more elements")
        print()
    return 1


def main():
    ap = argparse.ArgumentParser(description="Run axe-core over a page via Playwright.")
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--url", help="URL to audit (e.g. http://localhost:5173)")
    src.add_argument("--file", help="Local HTML file to audit")
    ap.add_argument(
        "--tags",
        default="wcag2a,wcag2aa,wcag21a,wcag21aa",
        help="Comma-separated axe rule tags (default: WCAG 2.0/2.1 A+AA). Empty for all.",
    )
    ap.add_argument("--axe-path", help="Local axe.min.js path for offline runs.")
    ap.add_argument("--json", dest="json_out", help="Also write raw axe JSON to this path.")
    ap.add_argument(
        "--reduced-motion",
        action="store_true",
        help="Emulate prefers-reduced-motion: reduce.",
    )
    args = ap.parse_args()

    target = args.url if args.url else Path(args.file).resolve().as_uri()

    try:
        axe_source = load_axe(args.axe_path)
        options = build_axe_options(args.tags)
        result = run(target, axe_source, options, args.reduced_motion)
    except ImportError:
        print(
            "ERROR: Playwright not installed. Run:\n"
            "  pip install playwright && playwright install chromium",
            file=sys.stderr,
        )
        return 2
    except Exception as e:  # noqa: BLE001
        print(f"ERROR running axe audit: {e}", file=sys.stderr)
        return 2

    if args.json_out:
        Path(args.json_out).write_text(json.dumps(result, indent=2))
        print(f"(raw axe JSON written to {args.json_out})\n")

    return render_report(result)


if __name__ == "__main__":
    sys.exit(main())
