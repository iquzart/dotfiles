#!/usr/bin/env python3
"""Scaffold container deliverables from the skill's assets/.

Writes Containerfile, .dockerignore, Makefile, and optionally compose.yaml and
.env.example into --dest. Never overwrites existing files: they are skipped and
reported so they can be merged by hand.

Usage:
  scaffold.py --lang go --name svc --port 8080 --org acme --repo svc \
      [--description "..."] [--compose] [--with-db] [--dest .]
"""
import argparse
import re
import sys
from pathlib import Path

ASSETS = Path(__file__).resolve().parent.parent / "assets"

HEALTHCHECK = {
    "go": '["CMD", "/app/{name}", "healthcheck"]',
    "generic": '["CMD", "/app/{name}", "healthcheck"]',
    "node": '["CMD", "node", "dist/healthcheck.js"]',
}


def strip_blocks(text: str, tag: str) -> str:
    """Remove every '# >>> tag' ... '# <<< tag' block, markers included."""
    pattern = re.compile(
        rf"^[ \t]*# >>> {tag}[ \t]*\n.*?^[ \t]*# <<< {tag}[ \t]*\n?", re.S | re.M
    )
    return pattern.sub("", text)


def keep_blocks(text: str, tag: str) -> str:
    """Keep block contents but drop the marker lines."""
    pattern = re.compile(rf"^[ \t]*# (?:>>>|<<<) {tag}[ \t]*\n", re.M)
    return pattern.sub("", text)


def render(text: str, ctx: dict) -> str:
    for key, value in ctx.items():
        text = text.replace("{{" + key + "}}", value)
    return text


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--lang", choices=["go", "node", "generic"], default="generic")
    ap.add_argument("--name", required=True, help="service name (matches repo/component)")
    ap.add_argument("--port", default="8080")
    ap.add_argument("--org", default="<org>")
    ap.add_argument("--repo", help="repository name (default: --name)")
    ap.add_argument("--description", default="<short description>")
    ap.add_argument("--compose", action="store_true", help="also write compose.yaml and .env.example")
    ap.add_argument("--with-db", action="store_true", help="include a Postgres service (needs --compose)")
    ap.add_argument("--dest", default=".")
    args = ap.parse_args()

    if args.with_db and not args.compose:
        ap.error("--with-db requires --compose")

    dest = Path(args.dest)
    dest.mkdir(parents=True, exist_ok=True)
    ctx = {
        "NAME": args.name,
        "PORT": args.port,
        "ORG": args.org,
        "REPO": args.repo or args.name,
        "DESCRIPTION": args.description,
        "HEALTHCHECK_TEST": HEALTHCHECK[args.lang].format(name=args.name),
    }

    def prep(text: str, tags_off=(), tags_on=()) -> str:
        for t in tags_off:
            text = strip_blocks(text, t)
        for t in tags_on:
            text = keep_blocks(text, t)
        return render(text, ctx)

    outputs = {}
    outputs["Containerfile"] = prep((ASSETS / f"Containerfile.{args.lang}").read_text())
    outputs[".dockerignore"] = (ASSETS / "dockerignore").read_text()

    makefile = (ASSETS / "Makefile").read_text()
    if args.compose:
        makefile = keep_blocks(makefile, "compose")
    else:
        makefile = strip_blocks(makefile, "compose")
        makefile = "\n".join(l for l in makefile.split("\n") if "# compose-only" not in l)
    makefile = makefile.replace(" # compose-only", "")
    if not args.compose:
        makefile = makefile.replace(" (and compose file if present)", "")
        makefile = makefile.replace("up down logs ps config", "").replace(".PHONY: help build run lint size clean ", ".PHONY: help build run lint size clean")
        makefile = "\n".join(l for l in makefile.split("\n") if not l.startswith("COMPOSE "))
    outputs["Makefile"] = render(makefile, ctx)

    if args.compose:
        db_on, db_off = (("db",), ()) if args.with_db else ((), ("db",))
        outputs["compose.yaml"] = prep((ASSETS / "compose.yaml").read_text(), db_off, db_on)
        outputs[".env.example"] = prep((ASSETS / "env.example").read_text(), db_off, db_on)

    written, skipped = [], []
    for fname, content in outputs.items():
        target = dest / fname
        if target.exists():
            skipped.append(fname)
            continue
        target.write_text(content)
        written.append(fname)

    for f in written:
        print(f"created  {dest / f}")
    for f in skipped:
        print(f"skipped  {dest / f} (exists; merge by hand, see assets/ and references/)")

    left = sorted({m for f in written for m in re.findall(r"<[a-zA-Z][^>\n]*>", (dest / f).read_text())})
    if left:
        print("\nResolve these placeholders before use (check.py flags them as Blockers):")
        for m in left:
            print(f"  {m}")
    print("\nNext: python scripts/check.py", dest)
    return 0


if __name__ == "__main__":
    sys.exit(main())
