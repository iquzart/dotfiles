#!/usr/bin/env python3
"""Static rule checker for Containerfiles/Dockerfiles and compose files.

Usage:
  check.py <path> [<path> ...]    file(s) or directory(ies) to scan

Output, one finding per line, ordered by severity:
  [Severity] file:line - issue - fix

Exit code 1 if any Blocker is found, else 0. Containerfile checks use only the
standard library. Compose checks need PyYAML and are skipped with a note if it
is not installed. This complements, and does not replace, hadolint.
"""

import re
import sys
from pathlib import Path

SEV_ORDER = {"Blocker": 0, "Major": 1, "Minor": 2}
SKIP_DIRS = {".git", "node_modules", "vendor", ".venv", "dist", "build"}
SECRET_NAME = re.compile(
    r"(PASSWORD|PASSWD|SECRET|TOKEN|API_?KEY|PRIVATE_?KEY|CREDENTIAL|ACCESS_?KEY)", re.I
)
SENSITIVE_FILE = re.compile(
    r"(^|/)(\.env(\.(?!example$)[\w.-]+)?|id_rsa|id_ed25519|\.npmrc|\.pypirc|credentials)$|\.(pem|key|p12|pfx)$",
    re.I,
)
PLACEHOLDER = re.compile(r"<[A-Za-z][^<>\s]*(?:[ -][^<>\s]+)*>")
OCI_LABELS = [
    "org.opencontainers.image.source",
    "org.opencontainers.image.title",
    "org.opencontainers.image.description",
    "org.opencontainers.image.version",
    "org.opencontainers.image.revision",
    "org.opencontainers.image.created",
]
DYNAMIC_ARGS = {"VERSION", "REVISION", "CREATED"}

findings = []


def add(sev, path, line, issue, fix):
    findings.append((SEV_ORDER[sev], sev, str(path), line, issue, fix))


# ----------------------------------------------------------------- Containerfile
def parse_instructions(text):
    """Return [(lineno, INSTRUCTION, args)] joining continuations, skipping comments."""
    out, buf, start = [], "", None
    for i, raw in enumerate(text.splitlines(), 1):
        stripped = raw.strip()
        if not buf and (not stripped or stripped.startswith("#")):
            continue
        if stripped.startswith("#") and buf:
            continue  # comment inside a continued instruction
        if start is None:
            start = i
        if stripped.endswith("\\"):
            buf += stripped[:-1].rstrip() + " "
            continue
        buf += stripped
        parts = buf.split(None, 1)
        out.append((start, parts[0].upper(), parts[1] if len(parts) > 1 else ""))
        buf, start = "", None
    if buf:
        parts = buf.split(None, 1)
        out.append((start, parts[0].upper(), parts[1] if len(parts) > 1 else ""))
    return out


def strip_flags(args):
    toks = args.split()
    while toks and toks[0].startswith("--"):
        toks.pop(0)
    return toks


def check_containerfile(path: Path):
    text = path.read_text(errors="replace")
    ins = parse_instructions(text)
    if not ins:
        return

    # Global ARG defaults (before first FROM)
    gargs = {}
    for _, name, args in ins:
        if name == "FROM":
            break
        if name == "ARG":
            k, _, v = args.partition("=")
            gargs[k.strip()] = v.strip().strip('"')

    def resolve(s):
        return re.sub(
            r"\$\{(\w+)\}|\$(\w+)",
            lambda m: gargs.get(m.group(1) or m.group(2), m.group(0)),
            s,
        )

    # Unresolved placeholders in instructions (comments already skipped)
    for ln, name, args in ins:
        for m in PLACEHOLDER.findall(args):
            add(
                "Blocker",
                path,
                ln,
                f"unresolved placeholder {m}",
                "replace with a real value (pin real versions and digests)",
            )

    # Stages
    stages, cur = [], None
    for ln, name, args in ins:
        if name == "FROM":
            toks = [t for t in args.split() if not t.startswith("--")]
            image = toks[0] if toks else ""
            alias = toks[2] if len(toks) >= 3 and toks[1].upper() == "AS" else None
            cur = {"line": ln, "image": image, "alias": alias, "ins": []}
            stages.append(cur)
        elif cur is not None:
            cur["ins"].append((ln, name, args))

    if not stages:
        add("Major", path, 1, "no FROM instruction found", "add a base image")
        return

    names = {s["alias"].lower() for s in stages if s["alias"]}
    for s in stages:
        img = resolve(s["image"])
        if img.lower() == "scratch" or img.lower() in names:
            continue
        if PLACEHOLDER.search(img):
            continue  # already reported
        last = img.rsplit("/", 1)[-1]
        has_digest = "@sha256:" in img
        tag = None
        if ":" in last.split("@")[0]:
            tag = last.split("@")[0].split(":", 1)[1]
        if "$" in img:
            add(
                "Minor",
                path,
                s["line"],
                f"cannot resolve image reference '{s['image']}'",
                "give the ARG a default so tag and digest are auditable",
            )
            continue
        if tag == "latest" or (tag is None and not has_digest):
            add(
                "Blocker",
                path,
                s["line"],
                f"base image '{img}' is {'tagged latest' if tag else 'untagged'}",
                "pin an explicit version tag and digest",
            )
        elif not has_digest:
            add(
                "Minor",
                path,
                s["line"],
                f"base image '{img}' is tagged but not digest-pinned",
                "pin with @sha256:<digest> and enable Renovate/Dependabot",
            )

    if len(stages) < 2:
        add(
            "Major",
            path,
            stages[0]["line"],
            "single-stage build",
            "split into a build stage and a minimal runtime stage",
        )

    final = stages[-1]
    fins = final["ins"]

    # USER
    users = [(ln, a.strip()) for ln, n, a in fins if n == "USER"]
    if not users:
        add(
            "Blocker",
            path,
            final["line"],
            "runtime stage never sets USER (runs as root unless base says otherwise)",
            "set a numeric non-root USER (e.g. USER 10001:10001)",
        )
    else:
        ln, u = users[-1]
        if u.split(":")[0] in ("root", "0"):
            add(
                "Blocker",
                path,
                ln,
                "runtime stage runs as root",
                "use a numeric non-root USER",
            )
        elif "$" not in u and not re.fullmatch(r"\d+(:\d+)?", u):
            add(
                "Major",
                path,
                ln,
                f"USER '{u}' is not numeric (Kubernetes runAsNonRoot cannot verify it)",
                "use a numeric UID:GID",
            )

    # Whole-file checks
    for st in stages:
        for ln, name, args in st["ins"]:
            if name == "HEALTHCHECK":
                add(
                    "Major",
                    path,
                    ln,
                    "HEALTHCHECK in a Containerfile",
                    "remove it; define health in compose and the orchestration platform",
                )
            if name in ("ARG", "ENV"):
                key = args.split("=", 1)[0].split()[0] if args else ""
                keys = [key]
                if name == "ENV" and "=" in args:
                    keys = re.findall(r"(\w+)=", args)
                for k in keys:
                    if k and SECRET_NAME.search(k):
                        add(
                            "Blocker",
                            path,
                            ln,
                            f"{name} '{k}' looks like a secret",
                            "remove it; use RUN --mount=type=secret at build time and runtime injection otherwise",
                        )
            if name in ("COPY", "ADD"):
                toks = strip_flags(args)
                if "--from" in args:
                    continue
                for src in toks[:-1]:
                    if SENSITIVE_FILE.search(src.strip('"')):
                        add(
                            "Blocker",
                            path,
                            ln,
                            f"{name} copies sensitive-looking file '{src}'",
                            "do not copy secrets or credentials into the image",
                        )
            if name == "ADD":
                src = (strip_flags(args) or [""])[0]
                if src.startswith(("http://", "https://")):
                    add(
                        "Minor",
                        path,
                        ln,
                        "ADD from a URL",
                        "use RUN curl with checksum verification",
                    )
                elif not re.search(r"\.(tar|tgz|tar\.\w+)$", src):
                    add("Minor", path, ln, "ADD used for a plain file", "use COPY")
            if name in ("ENTRYPOINT", "CMD") and not args.lstrip().startswith("["):
                add(
                    "Major",
                    path,
                    ln,
                    f"shell-form {name}",
                    f'use exec form: {name} ["bin", "arg"]',
                )
            if name == "RUN":
                if re.search(r"(curl|wget)[^|;&]*\|\s*(sudo\s+)?(ba)?sh\b", args):
                    add(
                        "Major",
                        path,
                        ln,
                        "pipes a download straight into a shell",
                        "download, verify a checksum, then run",
                    )
                if "apt-get install" in args or "apt install" in args:
                    if "--no-install-recommends" not in args:
                        add(
                            "Minor",
                            path,
                            ln,
                            "apt-get install without --no-install-recommends",
                            "add --no-install-recommends",
                        )
                    if "/var/lib/apt/lists" not in args:
                        add(
                            "Minor",
                            path,
                            ln,
                            "apt lists not cleaned in the same RUN",
                            "append && rm -rf /var/lib/apt/lists/*",
                        )
        # COPY . . before any dependency install
        first_copy = next(
            ((ln, a) for ln, n, a in st["ins"] if n == "COPY" and "--from" not in a),
            None,
        )
        if first_copy and strip_flags(first_copy[1]) in (
            ["."] * 2,
            [".", "./"],
            ["./", "./"],
        ):
            if any(n == "RUN" and ln > first_copy[0] for ln, n, a in st["ins"]):
                add(
                    "Minor",
                    path,
                    first_copy[0],
                    "COPY . . before dependency install defeats layer caching",
                    "copy dependency manifests and install first, then copy the source",
                )

    # Labels
    label_text = " ".join(a for ln, n, a in fins if n == "LABEL")
    missing = [l for l in OCI_LABELS if l not in label_text]
    if missing:
        add(
            "Major",
            path,
            final["line"],
            "missing OCI labels: " + ", ".join(m.rsplit(".", 1)[1] for m in missing),
            "add the standard org.opencontainers.image.* labels in the final stage",
        )
    final_args = {}
    for idx, (ln, n, a) in enumerate(fins):
        if n == "ARG":
            final_args[a.split("=")[0].strip()] = idx
    for ln, n, a in fins:
        if n == "LABEL":
            for var in re.findall(r"\$\{?(\w+)\}?", a):
                if var in DYNAMIC_ARGS and var not in final_args:
                    add(
                        "Major",
                        path,
                        ln,
                        f"LABEL uses ${var} but ARG {var} is not declared in the final stage (label will be empty)",
                        "declare the ARG in the final stage before the LABEL",
                    )
    last_build = max(
        (i for i, (ln, n, a) in enumerate(fins) if n in ("RUN", "COPY", "ADD")),
        default=-1,
    )
    early = [k for k, i in final_args.items() if k in DYNAMIC_ARGS and i < last_build]
    if early:
        add(
            "Minor",
            path,
            final["line"],
            f"dynamic label ARG(s) {', '.join(sorted(early))} declared before later layers (busts cache)",
            "move them to the end of the final stage",
        )

    if not any(n == "EXPOSE" for ln, n, a in fins):
        add(
            "Minor",
            path,
            final["line"],
            "no EXPOSE in runtime stage",
            "document each listening port with EXPOSE",
        )

    # Base image family
    img = resolve(final["image"]).rsplit("/", 1)[-1].lower()
    base = img.split(":")[0].split("@")[0]
    tag = img.split(":", 1)[1] if ":" in img else ""
    if (
        base in ("ubuntu", "debian", "centos", "fedora", "rockylinux", "almalinux")
        and "slim" not in tag
    ):
        add(
            "Minor",
            path,
            final["line"],
            f"full OS runtime base '{base}'",
            "use distroless, -slim, or scratch unless a shell/package manager is required",
        )
    if "alpine" in img:
        add(
            "Minor",
            path,
            final["line"],
            "Alpine runtime base (musl)",
            "confirm the app is tested on musl, or use distroless/-slim",
        )

    # Siblings
    d = path.parent
    if path.name.lower().startswith("dockerfile"):
        add(
            "Minor",
            path,
            1,
            "named Dockerfile",
            "team standard is Containerfile unless the platform requires Dockerfile",
        )
    if (
        any((d / n).exists() for n in ("Containerfile", "Dockerfile"))
        and (d / "Containerfile").exists()
        and (d / "Dockerfile").exists()
    ):
        add("Major", path, 1, "both Containerfile and Dockerfile exist", "keep one")
    ignores = [
        d / ".dockerignore",
        d / ".containerignore",
        d / f"{path.name}.dockerignore",
    ]
    if not any(p.exists() for p in ignores):
        add(
            "Blocker",
            path,
            1,
            "no .dockerignore next to the build file",
            "add .dockerignore (see assets/dockerignore)",
        )
    if (d / ".dockerignore").exists() and (d / ".containerignore").exists():
        add(
            "Minor",
            path,
            1,
            "both .dockerignore and .containerignore exist",
            "keep one (Podman prefers .containerignore)",
        )
    if not any((d / n).exists() for n in ("Makefile", "makefile", "GNUmakefile")):
        add(
            "Major",
            path,
            1,
            "no Makefile next to the build file",
            "add one (see assets/Makefile, references/makefile.md)",
        )


# ----------------------------------------------------------------------- compose
def check_compose(path: Path):
    try:
        import yaml
    except ImportError:
        print(
            f"note: PyYAML not installed; skipped compose checks for {path}",
            file=sys.stderr,
        )
        return
    text = path.read_text(errors="replace")
    try:
        doc = yaml.safe_load(text) or {}
    except yaml.YAMLError as e:
        add("Blocker", path, 1, f"invalid YAML: {e}", "fix the syntax")
        return
    lines = text.splitlines()

    def line_of(key):
        for i, l in enumerate(lines, 1):
            if re.match(rf"^\s*{re.escape(key)}\s*:", l):
                return i
        return 1

    for m in sorted(set(PLACEHOLDER.findall(text))):
        add(
            "Blocker",
            path,
            1,
            f"unresolved placeholder {m}",
            "replace with a real value",
        )
    if "version" in doc:
        add(
            "Minor",
            path,
            line_of("version"),
            "obsolete top-level 'version' key",
            "remove it",
        )
    services = doc.get("services") or {}
    if not doc.get("networks"):
        add(
            "Major",
            path,
            1,
            "no named network defined",
            "add a top-level named network and attach services to it",
        )

    for name, svc in services.items():
        ln = line_of(name)
        svc = svc or {}
        if name in ("app", "web"):
            add(
                "Minor",
                path,
                ln,
                f"generic service name '{name}'",
                "name it after the repo/component",
            )
        image = svc.get("image")
        if image and not svc.get("build"):
            last = image.rsplit("/", 1)[-1]
            tag = (
                last.split("@")[0].split(":", 1)[1]
                if ":" in last.split("@")[0]
                else None
            )
            if tag == "latest" or (tag is None and "@sha256:" not in image):
                add(
                    "Blocker",
                    path,
                    ln,
                    f"{name}: image '{image}' is {'latest' if tag else 'untagged'}",
                    "pin a version tag and digest",
                )
            elif "@sha256:" not in image:
                add(
                    "Minor",
                    path,
                    ln,
                    f"{name}: image '{image}' not digest-pinned",
                    "pin with @sha256:<digest>",
                )
        limits = ((svc.get("deploy") or {}).get("resources") or {}).get("limits") or {}
        if not (limits.get("cpus") and limits.get("memory")):
            add(
                "Major",
                path,
                ln,
                f"{name}: missing deploy.resources.limits (cpus and memory)",
                "set cpu and memory limits",
            )
        if not svc.get("networks") and doc.get("networks"):
            add(
                "Major",
                path,
                ln,
                f"{name}: not attached to a named network",
                "add networks: [<name>]",
            )
        if "ALL" not in [str(c).upper() for c in (svc.get("cap_drop") or [])]:
            add(
                "Minor",
                path,
                ln,
                f"{name}: cap_drop: [ALL] not set",
                "drop all capabilities, add back only what is needed",
            )
        if not any(
            "no-new-privileges" in str(o) for o in (svc.get("security_opt") or [])
        ):
            add(
                "Minor",
                path,
                ln,
                f"{name}: no-new-privileges not set",
                "add security_opt: [no-new-privileges:true]",
            )
        for p in svc.get("ports") or []:
            if isinstance(p, dict):
                if p.get("published") and not p.get("host_ip"):
                    add(
                        "Minor",
                        path,
                        ln,
                        f"{name}: port {p.get('published')} not bound to loopback",
                        "set host_ip: 127.0.0.1 for local dev",
                    )
            else:
                s = str(p)
                if ":" in s and not re.match(
                    r"^(127\.0\.0\.1|\[?::1\]?|localhost):", s
                ):
                    add(
                        "Minor",
                        path,
                        ln,
                        f"{name}: port '{s}' not bound to loopback",
                        "prefix with 127.0.0.1: for local dev",
                    )
        for v in svc.get("volumes") or []:
            if isinstance(v, str) and v.startswith("/") and ":" not in v:
                add(
                    "Minor",
                    path,
                    ln,
                    f"{name}: anonymous volume '{v}'",
                    "use a named volume",
                )
        env = svc.get("environment") or {}
        pairs = (
            env.items()
            if isinstance(env, dict)
            else [tuple(e.split("=", 1)) for e in env if "=" in str(e)]
        )
        for k, v in pairs:
            if (
                SECRET_NAME.search(str(k))
                and v not in (None, "")
                and not str(v).startswith("${")
            ):
                add(
                    "Blocker",
                    path,
                    ln,
                    f"{name}: environment '{k}' holds a literal secret",
                    "move to a gitignored env_file or platform secret",
                )
        dep = svc.get("depends_on")
        if isinstance(dep, list):
            add(
                "Major",
                path,
                ln,
                f"{name}: depends_on uses list form (startup order only)",
                "use condition: service_healthy",
            )
        elif isinstance(dep, dict):
            for target, cfg in dep.items():
                cond = (cfg or {}).get("condition")
                if cond != "service_healthy":
                    add(
                        "Major",
                        path,
                        ln,
                        f"{name}: depends_on '{target}' lacks condition: service_healthy",
                        "add condition: service_healthy",
                    )
                else:
                    hc = ((services.get(target) or {}).get("healthcheck")) or {}
                    if not hc or hc.get("disable"):
                        add(
                            "Major",
                            path,
                            line_of(target),
                            f"{target}: has no healthcheck but {name} waits on it",
                            "add a healthcheck",
                        )


# ------------------------------------------------------------------------ driver
def is_containerfile(p: Path):
    n = p.name
    return (
        n in ("Containerfile", "Dockerfile")
        or n.startswith(("Containerfile.", "Dockerfile."))
    ) and not n.endswith(("dockerignore", ".md"))


def is_compose(p: Path):
    return bool(re.fullmatch(r"(docker-)?compose(\.[\w-]+)?\.ya?ml", p.name))


def collect(paths):
    files = []
    for raw in paths:
        p = Path(raw)
        if p.is_file():
            files.append(p)
        elif p.is_dir():
            for f in sorted(p.rglob("*")):
                if f.is_file() and not (set(f.parts) & SKIP_DIRS):
                    files.append(f)
        else:
            print(f"warning: {raw} not found", file=sys.stderr)
    return files


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    files = collect(argv)
    found_any = False
    for f in files:
        if is_containerfile(f):
            found_any = True
            check_containerfile(f)
        elif is_compose(f):
            found_any = True
            check_compose(f)
    if not found_any:
        print("No Containerfile, Dockerfile, or compose file found.")
        return 0

    counts = {"Blocker": 0, "Major": 0, "Minor": 0}
    for _, sev, path, line, issue, fix in sorted(
        findings, key=lambda f: (f[0], f[2], f[3] or 0)
    ):
        counts[sev] += 1
        print(f"[{sev}] {path}:{line} - {issue} - {fix}")
    print(
        f"\n{counts['Blocker']} Blocker, {counts['Major']} Major, {counts['Minor']} Minor"
    )
    return 1 if counts["Blocker"] else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
