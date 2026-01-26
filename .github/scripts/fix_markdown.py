#!/usr/bin/env python3
from pathlib import Path
import re

def guess_fence_lang(code: str) -> str:
    sample = "\n".join([ln for ln in code.splitlines()[:20] if ln.strip()][:10]).lower()
    if any(k in sample for k in ["terraform {", "provider ", "module ", "variable ", "output ", "resource "]):
        return "hcl"
    if any(k in sample for k in ["terraform ", "codreum ", "cd ", "ls ", "git ", "python ", "npm ", "npx "]):
        return "bash"
    if sample.startswith("{") or sample.startswith("["):
        return "json"
    return "text"

def fix_markdown(text: str) -> str:
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"(?<![\\w\\[])(support@codreum\\.com)(?![\\w\\]])", r"[support@codreum.com](mailto:support@codreum.com)", text)
    lines = [re.sub(r"[ \\t]+$", "", ln) for ln in text.split("\n")]

    out = []
    in_code = False
    i = 0
    while i < len(lines):
        ln = lines[i]
        m = re.match(r"^(```|~~~)(.*)$", ln)
        if m:
            marker, rest = m.group(1), m.group(2)
            if not in_code:
                if out and out[-1] != "":
                    out.append("")
                if rest.strip() == "":
                    j = i + 1
                    code_lines = []
                    while j < len(lines):
                        if re.match(rf"^{re.escape(marker)}\\s*$", lines[j]):
                            break
                        code_lines.append(lines[j])
                        j += 1
                    out.append(marker + guess_fence_lang("\n".join(code_lines)))
                else:
                    out.append(marker + rest.strip())
                in_code = True
            else:
                out.append(marker)
                in_code = False
                if i + 1 < len(lines) and lines[i + 1].strip() != "":
                    out.append("")
            i += 1
            continue
        out.append(ln)
        i += 1

    def is_heading(s): return bool(re.match(r"^#{1,6}\\s+\\S", s))
    def is_list_item(s): return bool(re.match(r"^\\s*([-*+]|\\d+\\.)\\s+\\S", s))
    def is_fence(s): return bool(re.match(r"^(```|~~~)", s))

    out2 = []
    in_code = False
    i = 0
    while i < len(out):
        ln = out[i]
        if is_fence(ln):
            out2.append(ln)
            in_code = not in_code
            i += 1
            continue
        if in_code:
            out2.append(ln)
            i += 1
            continue
        if is_heading(ln):
            if out2 and out2[-1] != "":
                out2.append("")
            out2.append(ln)
            if i + 1 < len(out) and out[i + 1] != "" and not is_fence(out[i + 1]):
                out2.append("")
            i += 1
            continue
        if is_list_item(ln):
            if out2 and out2[-1] != "" and not is_list_item(out2[-1]):
                out2.append("")
            while i < len(out) and (is_list_item(out[i]) or out[i].startswith("  ") or out[i].startswith("\t")):
                out2.append(out[i])
                i += 1
                if i < len(out) and out[i] == "":
                    out2.append("")
                    i += 1
                    break
            if out2 and out2[-1] != "" and i < len(out) and out[i] != "":
                out2.append("")
            continue
        out2.append(ln)
        i += 1

    collapsed = []
    blanks = 0
    for ln in out2:
        if ln == "":
            blanks += 1
            if blanks <= 1:
                collapsed.append(ln)
        else:
            blanks = 0
            collapsed.append(ln)
    return "\n".join(collapsed).rstrip("\n") + "\n"

def main():
    changed = 0
    for p in Path('.').rglob('*.md'):
        if '.git' in p.parts:
            continue
        old = p.read_text(encoding='utf-8')
        new = fix_markdown(old)
        if new != old:
            p.write_text(new, encoding='utf-8')
            changed += 1
    print(f'Updated {changed} file(s).')

if __name__ == '__main__':
    main()
