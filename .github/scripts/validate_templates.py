import re
from pathlib import Path
import sys

TEMPLATES_DIR = Path("templates")

REQUIRED_SOURCE = 'registry.codreum.com/codreum/dnsciz/aws'
VERSION_RE = re.compile(r'^\s*version\s*=\s*"\d+\.\d+\.\d+"\s*$', re.MULTILINE)

def fail(msg: str) -> None:
  print(f"ERROR: {msg}")
  sys.exit(1)

def main() -> None:
  if not TEMPLATES_DIR.exists():
    fail("templates/ directory not found")

  tf_files = list(TEMPLATES_DIR.rglob("*.tf"))
  if not tf_files:
    fail("No .tf files found under templates/")

  # Check each template has at least one module source pointing to the private registry
  # and that the module version is pinned (x.y.z).
  source_hits = 0
  unpinned = []

  for tf in tf_files:
    text = tf.read_text(encoding="utf-8", errors="replace")

    if REQUIRED_SOURCE in text:
      source_hits += 1

    # If a file contains the source, it should also contain a pinned version.
    if REQUIRED_SOURCE in text and not VERSION_RE.search(text):
      unpinned.append(str(tf))

    # Guardrail: prevent accidentally publishing module code or local module sources in templates.
    if re.search(r'^\s*source\s*=\s*"\./', text, re.MULTILINE):
      fail(f"Local module source found (./...) in {tf}. Templates should reference the Codreum registry.")

    if "registry.terraform.io" in text:
      # allowed for providers, but not as module source; conservative guardrail
      if re.search(r'^\s*source\s*=\s*".*registry\.terraform\.io.*"\s*$', text, re.MULTILINE):
        fail(f"Public registry module source found in {tf}. Expected Codreum private registry module source.")

  if source_hits == 0:
    fail(f"No template references '{REQUIRED_SOURCE}'. Did the module source change?")

  if unpinned:
    fail("Some templates reference the Pro module but do not pin version = \"x.y.z\":\n" + "\n".join(unpinned))

  print("OK: templates look consistent (registry source + pinned version + no local module sources).")

if __name__ == "__main__":
  main()
