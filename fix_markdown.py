#!/usr/bin/env python3
"""
fix_markdown.py

Best-effort auto-fixer for common markdownlint-cli2 issues:
- MD009 trailing spaces
- MD012 multiple blank lines
- MD022 blanks around headings
- MD032 blanks around lists
- MD034 bare URLs (wrap with <...>)
- MD036 emphasis used instead of heading (**Title** -> ### Title)
- MD049 emphasis style for "None yet." placeholder (_None yet._ -> *None yet.*)
- MD028 blank line inside blockquote (drops standalone ">" blank lines; also converts common "Notes on ..." blockquotes)

Usage:
  python3 fix_markdown.py
  python3 fix_markdown.py --check   (exit non-zero if changes would be made)
"""

from __future__ import annotations
from pathlib import Path
import argparse
import re
import sys

EXCLUDE_DIRS = {".git", "node_modules", ".terraform", ".venv", "venv", "dist", "build", ".idea", ".vscode"}

def find_repo_root(start: Path) -> Path:
    cur = start.resolve()
    for _ in range(8):
        if (cur / ".git").exists() or (cur / ".github").exists():
            return cur
        if cur.parent == cur:
            break
        cur = cur.parent
    return start.resolve()

def normalize_newlines(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n")

def strip_trailing_ws(text: str) -> str:
    return "\n".join([re.sub(r"[ \t]+$", "", ln) for ln in text.split("\n")])

def collapse_blank_lines(text: str) -> str:
    return re.sub(r"\n{3,}", "\n\n", text)

def ensure_single_trailing_newline(text: str) -> str:
    return text.rstrip("\n") + "\n"

def fix_emphasis_style(text: str) -> str:
    return re.sub(r"_None yet\._", r"*None yet.*", text)

def fix_bare_urls(text: str) -> str:
    # Wrap bare URLs with angle brackets. Skip those already in (), [], <>.
    pattern = re.compile(r'(?<![<(\\[])https?://[^\s)>\]]+')
    return pattern.sub(lambda m: f"<{m.group(0)}>", text)

def convert_emphasis_only_lines_to_headings(text: str) -> str:
    lines = text.splitlines()
    out = []
    in_code = False
    def is_fence(s): return bool(re.match(r"^(```|~~~)", s))
    for ln in lines:
        if is_fence(ln):
            in_code = not in_code
            out.append(ln)
            continue
        if not in_code:
            m = re.match(r"^\*\*(.+?)\*\*$", ln.strip())
            if m:
                out.append(f"### {m.group(1).strip()}")
                continue
        out.append(ln)
    return "\n".join(out)

def fix_templates_notes_blockquotes(text: str) -> str:
    lines = text.splitlines()
    out = []
    in_code = False
    def is_fence(s): return bool(re.match(r"^(```|~~~)", s))
    i = 0
    while i < len(lines):
        ln = lines[i]
        if is_fence(ln):
            in_code = not in_code
            out.append(ln)
            i += 1
            continue
        if not in_code and re.match(r"^\s*>\s*Notes on dashboards:\s*$", ln):
            out.extend(["### Notes on dashboards", ""])
            i += 1
            while i < len(lines) and lines[i].lstrip().startswith(">"):
                l2 = re.sub(r"^\s*>\s?", "", lines[i])
                if l2.strip():
                    out.append(l2)
                i += 1
            out.append("")
            continue
        if not in_code and re.match(r"^\s*>\s*Notes on log-group keyed overrides:\s*$", ln):
            out.extend(["### Notes on log-group keyed overrides", ""])
            i += 1
            while i < len(lines) and lines[i].lstrip().startswith(">"):
                l2 = re.sub(r"^\s*>\s?", "", lines[i])
                if l2.strip():
                    out.append(l2)
                i += 1
            out.append("")
            continue
        # Drop standalone blank quote lines (fix MD028)
        if not in_code and re.match(r"^\s*>\s*$", ln):
            i += 1
            continue
        out.append(ln)
        i += 1
    return "\n".join(out)

def fix_headings_and_lists(text: str) -> str:
    lines = text.splitlines()
    out = []
    in_code = False

    def is_fence(s): return bool(re.match(r"^(```|~~~)", s))
    def is_heading(s): return bool(re.match(r"^#{1,6}\s+\S", s))
    def is_list(s): return bool(re.match(r"^\s*([-*+]|\d+\.)\s+\S", s))
    def is_blank(s): return s.strip() == ""

    i = 0
    while i < len(lines):
        ln = lines[i]
        if is_fence(ln):
            in_code = not in_code
            out.append(ln)
            i += 1
            continue

        if not in_code:
            if is_heading(ln):
                if out and not is_blank(out[-1]):
                    out.append("")
                out.append(ln)
                if i + 1 < len(lines) and not is_blank(lines[i+1]):
                    out.append("")
                i += 1
                continue

            if is_list(ln):
                if out and not is_blank(out[-1]):
                    out.append("")
                out.append(ln)
                i += 1
                continue

            if out and is_list(out[-1]) and not is_blank(ln) and not is_list(ln) and not is_heading(ln):
                out.append("")

        out.append(ln)
        i += 1

    return "\n".join(out)

def full_fix(text: str) -> str:
    text = normalize_newlines(text)
    text = strip_trailing_ws(text)
    text = fix_emphasis_style(text)
    text = fix_templates_notes_blockquotes(text)
    text = convert_emphasis_only_lines_to_headings(text)
    text = fix_bare_urls(text)
    text = fix_headings_and_lists(text)
    # Replace placeholder lone '-' list items often used in changelogs
    text = re.sub(r"(?m)^\s*-\s*$", "- *None yet.*", text)
    text = collapse_blank_lines(text)
    text = ensure_single_trailing_newline(text)
    return text

def iter_md_files(root: Path):
    for p in root.rglob("*.md"):
        if any(part in EXCLUDE_DIRS for part in p.parts):
            continue
        yield p

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="Do not write; exit 1 if changes are needed.")
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
                p.write_text(after, encoding="utf-8", newline="\n")

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
