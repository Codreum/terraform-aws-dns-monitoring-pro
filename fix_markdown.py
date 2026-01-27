#!/usr/bin/env python3
"""
fix_markdown.py (v2)

Best-effort auto-fixer for common markdownlint-cli2 issues, including:
- MD009 trailing spaces
- MD012 multiple blank lines
- MD022 blanks around headings
- MD032 blanks around lists
- MD028 blank line inside blockquote (removes standalone ">" lines)
- MD034 bare URLs / bare emails (wrap with <...>)
- MD036 emphasis used instead of heading (**Title** -> ### Title)
- MD049 emphasis style for "None yet." placeholder (_None yet._ -> *None yet.*)

Usage:
  # from repo root
  python3 fix_markdown.py

  # check-only mode (CI style)
  python3 fix_markdown.py --check
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Iterable

EXCLUDE_DIRS = {".git", "node_modules", ".terraform", ".venv", "venv", "dist", "build", ".idea", ".vscode"}

FENCE_RE = re.compile(r"^(\s*)(```|~~~)")
HEADING_RE = re.compile(r"^\s{0,3}#{1,6}\s+\S")
LIST_RE = re.compile(r"^\s*([-*+]|\d+\.)\s+\S")
HR_RE = re.compile(r"^\s{0,3}(-{3,}|\*{3,}|_{3,})\s*$")

# Emphasis-only "fake headings"
EMPH_ONLY_RE = re.compile(r"^\s*(\*\*|__)([^*_].*?)(\*\*|__)\s*$")

# Bare URL (skip those already inside <> or () or [])
BARE_URL_RE = re.compile(r'(?<![<(\[])https?://[^\s)>\]]+')
# Bare email (skip those already inside <> or () or [])
BARE_EMAIL_RE = re.compile(r'(?<![<(\[])\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b')

def find_repo_root(start: Path) -> Path:
    cur = start.resolve()
    for _ in range(10):
        if (cur / ".git").exists() or (cur / ".github").exists():
            return cur
        if cur.parent == cur:
            break
        cur = cur.parent
    return start.resolve()

def iter_md_files(root: Path) -> Iterable[Path]:
    for p in root.rglob("*.md"):
        if any(part in EXCLUDE_DIRS for part in p.parts):
            continue
        yield p

def normalize_newlines(text: str) -> str:
    return text.replace("\\r\\n", "\\n").replace("\\r", "\\n")

def strip_trailing_ws(text: str) -> str:
    return "\\n".join([re.sub(r"[ \\t]+$", "", ln) for ln in text.split("\\n")])

def fix_none_yet_emphasis(text: str) -> str:
    # Enforce asterisk style for the common placeholder
    return re.sub(r"_None yet\\._", r"*None yet.*", text)

def fix_bare_urls_and_emails(text: str) -> str:
    text = BARE_URL_RE.sub(lambda m: f"<{m.group(0)}>", text)
    text = BARE_EMAIL_RE.sub(lambda m: f"<{m.group(0)}>", text)
    return text

def unquote_list_items_and_drop_blank_blockquote_lines(lines: list[str]) -> list[str]:
    """
    - Drops standalone '>' lines (MD028)
    - Converts blockquote list items like '> - foo' into normal list items '- foo'
      (avoids MD032+MD028 conflict for lists inside blockquotes)
    """
    out: list[str] = []
    in_code = False

    for ln in lines:
        if FENCE_RE.match(ln):
            in_code = not in_code
            out.append(ln)
            continue
        if in_code:
            out.append(ln)
            continue

        # standalone blank quote lines => drop
        if re.match(r"^\\s*>\\s*$", ln):
            out.append("")
            continue

        # blockquote list items => unquote
        if re.match(r"^\\s*>\\s*([-*+]|\d+\\.)\\s+\\S", ln):
            out.append(re.sub(r"^\\s*>\\s*", "", ln))
            continue

        out.append(ln)

    return out

def convert_emphasis_only_lines_to_headings(lines: list[str]) -> list[str]:
    out: list[str] = []
    in_code = False

    for ln in lines:
        if FENCE_RE.match(ln):
            in_code = not in_code
            out.append(ln)
            continue
        if in_code:
            out.append(ln)
            continue

        m = EMPH_ONLY_RE.match(ln)
        if m:
            title = m.group(2).strip().rstrip(":")
            out.append(f"### {title}")
        else:
            out.append(ln)

    return out

def ensure_blanks_around_headings_and_lists(lines: list[str]) -> list[str]:
    """
    Ensures:
    - headings are surrounded by blank lines (MD022)
    - list blocks are surrounded by blank lines (MD032)
    """
    out: list[str] = []
    in_code = False
    i = 0

    while i < len(lines):
        ln = lines[i]

        if FENCE_RE.match(ln):
            in_code = not in_code
            out.append(ln)
            i += 1
            continue

        if in_code:
            out.append(ln)
            i += 1
            continue

        # Heading spacing
        if HEADING_RE.match(ln):
            if out and out[-1].strip() != "":
                out.append("")
            out.append(ln)
            # always ensure blank line after heading (unless next line is blank or EOF)
            if i + 1 < len(lines) and lines[i + 1].strip() != "":
                out.append("")
            i += 1
            continue

        # List blocks: add blank line before first item and after last item
        if LIST_RE.match(ln):
            if out and out[-1].strip() != "":
                out.append("")
            # consume contiguous list block
            while i < len(lines) and LIST_RE.match(lines[i]):
                out.append(lines[i])
                i += 1
            # after list block, ensure blank line unless next is blank/EOF
            if i < len(lines) and lines[i].strip() != "":
                out.append("")
            continue

        out.append(ln)
        i += 1

    return out

def collapse_multiple_blank_lines_preserving_fences(lines: list[str]) -> list[str]:
    out: list[str] = []
    in_code = False
    blank_run = 0

    for ln in lines:
        if FENCE_RE.match(ln):
            in_code = not in_code
            out.append(ln)
            blank_run = 0
            continue

        if in_code:
            out.append(ln)
            continue

        if ln.strip() == "":
            blank_run += 1
            if blank_run <= 1:
                out.append("")
        else:
            blank_run = 0
            out.append(ln)

    return out

def ensure_single_trailing_newline(text: str) -> str:
    return text.rstrip("\\n") + "\\n"

def full_fix(text: str) -> str:
    text = normalize_newlines(text)
    text = strip_trailing_ws(text)
    text = fix_none_yet_emphasis(text)
    text = fix_bare_urls_and_emails(text)

    lines = text.splitlines()
    lines = unquote_list_items_and_drop_blank_blockquote_lines(lines)
    lines = convert_emphasis_only_lines_to_headings(lines)
    lines = ensure_blanks_around_headings_and_lists(lines)
    lines = collapse_multiple_blank_lines_preserving_fences(lines)

    # Replace lone '-' list placeholders with a standard item
    lines = [("- *None yet.*" if re.fullmatch(r"\\s*-\\s*", ln) else ln) for ln in lines]

    text = "\\n".join(lines)
    text = ensure_single_trailing_newline(text)
    return text

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="Do not write; exit 1 if changes would be made.")
    args = ap.parse_args()

    root = find_repo_root(Path(__file__).parent)
    md_files = list(iter_md_files(root))

    changed = 0
    for p in md_files:
        before = p.read_text(encoding="utf-8", errors="replace")
        after = full_fix(before)
        if before != after:
            changed += 1
            if not args.check:
                p.write_text(after, encoding="utf-8", newline="\\n")

    if args.check:
        if changed:
            print(f"{changed} file(s) would be updated.")
            return 1
        print("No changes needed.")
        return 0

    print(f"Updated {changed} file(s). (scanned {len(md_files)} markdown file(s) under {root})")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
