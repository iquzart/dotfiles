import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"


class ContainerfileOrderTest(unittest.TestCase):
    def scaffold(self, lang: str) -> Path:
        root = tempfile.TemporaryDirectory()
        self.addCleanup(root.cleanup)
        subprocess.run(
            [
                sys.executable,
                SCRIPTS / "scaffold.py",
                "--lang",
                lang,
                "--name",
                "example",
                "--org",
                "acme",
                "--description",
                "Example",
                "--dest",
                root.name,
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        return Path(root.name) / "Containerfile"

    def check(self, containerfile: Path) -> str:
        result = subprocess.run(
            [sys.executable, SCRIPTS / "check.py", containerfile],
            capture_output=True,
            text=True,
        )
        # Scaffolds still have unresolved placeholders.
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("unresolved placeholder", result.stdout)
        return result.stdout

    def test_scaffolds_preserve_runtime_order(self):
        for lang in ("generic", "go", "node"):
            with self.subTest(lang=lang):
                containerfile = self.scaffold(lang)
                runtime = containerfile.read_text().rsplit("\nFROM ", 1)[1]
                instructions = re.findall(r"^([A-Z]+) (.+)$", runtime, re.MULTILINE)
                self.assertEqual(
                    instructions[:3],
                    [
                        ("ARG", "VERSION=dev"),
                        ("ARG", "REVISION=unknown"),
                        ("ARG", "CREATED=unknown"),
                    ],
                )
                self.assertEqual(
                    [name for name, _ in instructions if name in ("ARG", "LABEL")],
                    ["ARG", "ARG", "ARG", "LABEL"],
                )
                self.assertEqual(instructions[3][0], "LABEL")
                self.assertEqual(
                    [name for name, _ in instructions[-2:]], ["EXPOSE", "ENTRYPOINT"]
                )
                findings = self.check(containerfile)
                self.assertNotIn("dynamic label ARG", findings)
                self.assertNotIn("OCI labels appear after", findings)

    def test_checker_flags_metadata_moved_below_entrypoint(self):
        containerfile = self.scaffold("go")
        before, version, metadata = containerfile.read_text().partition(
            "ARG VERSION=dev\n"
        )
        block, after = metadata.split("\n\n", 1)
        containerfile.write_text(
            before + after.rstrip() + "\n\n" + version + block + "\n"
        )
        self.assertIn(
            "OCI labels appear after ENTRYPOINT or CMD", self.check(containerfile)
        )

    def test_checker_still_flags_runtime_run_cache(self):
        containerfile = self.scaffold("go")
        containerfile.write_text(
            containerfile.read_text().replace(
                "WORKDIR /app\n", "WORKDIR /app\nRUN true\n"
            )
        )
        self.assertIn("can invalidate a later RUN cache", self.check(containerfile))

    def test_checker_requires_arg_before_label(self):
        containerfile = self.scaffold("go")
        text = containerfile.read_text().replace("ARG VERSION=dev\n", "")
        containerfile.write_text(
            text.replace("WORKDIR /app", "ARG VERSION=dev\nWORKDIR /app")
        )
        self.assertIn(
            "LABEL uses $VERSION before ARG VERSION", self.check(containerfile)
        )


if __name__ == "__main__":
    unittest.main()
