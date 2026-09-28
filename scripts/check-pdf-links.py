#!/usr/bin/env python3
"""Resolve every clickable link in a built PDF.

`make links` checks references.bib. This checks what actually became a
URI annotation in the PDF, which is not the same set: a bibliography
style prints some fields and drops others. unsrtnat prints url and doi
but not eprint, so arXiv-only entries silently lost their links until
each was given an explicit url.

403 and 429 are reported but not failed. USENIX, SSRN and a few
publishers block scripted requests, and a link that is bot-blocked is
not a link that is broken.
"""
import io
import re
import subprocess
import sys
import zlib


def uris(path):
    """Every URI annotation, including those inside compressed streams."""
    d = io.open(path, "rb").read()
    found = set(re.findall(rb"/URI\s*\(([^)]{6,300})\)", d))
    for m in re.finditer(rb"stream\r?\n", d):
        start = m.end()
        end = d.find(b"endstream", start)
        try:
            found |= set(re.findall(rb"/URI\s*\(([^)]{6,300})\)",
                                    zlib.decompress(d[start:end])))
        except Exception:
            pass
    return sorted(u.decode("latin1") for u in found)


# acmart prints a placeholder DOI until ACM assigns a real one on
# acceptance. It is meant to 404 and is not a defect in the submission.
EXPECTED_404 = ('10.1145/nnnnnnn.nnnnnnn',)


def status(url):
    try:
        out = subprocess.run(
            ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}",
             "-L", "--max-time", "12", "-A", "Mozilla/5.0", url],
            capture_output=True, text=True, timeout=20)
        return out.stdout.strip()
    except Exception:
        return "000"


def main(paths):
    broken, blocked, total = [], [], 0
    for p in paths:
        links = uris(p)
        total += len(links)
        print(f"  {p}: {len(links)} clickable links")
        for u in links:
            c = status(u)
            if c[:1] in ("2", "3"):
                continue
            if any(e in u for e in EXPECTED_404):
                continue
            (blocked if c in ("403", "429") else broken).append((c, u, p))
    for c, u, p in blocked:
        print(f"  {c} blocked by bot protection, not broken: {u}")
    for c, u, p in broken:
        print(f"  {c} BROKEN: {u}")
    if broken:
        print(f"FAIL: {len(broken)} broken link(s)")
        return 1
    print(f"OK: {total} links, none broken"
          + (f", {len(blocked)} bot-blocked" if blocked else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
