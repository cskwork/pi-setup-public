#!/usr/bin/env python3
"""Assert the hand-maintained docs still match the config they describe.

Hand-maintained docs and safety policy can drift silently from active config.
These checks cover shipped regressions:
  1. README skill counts/tables out of sync with tracked skills
  2. agents/*.md pinning `model:`, which mutes every profile
  3. profiles referencing a skill that exists nowhere
  4. profile-table or default-model text disagreeing with settings
  5. agent files missing settings-owned model/fallback routes
  6. recursive rm spellings bypassing ask/deny rules

Run from the repo root: python3 scripts/check-docs.py
"""
from fnmatch import fnmatchcase
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GATES = ["specifier", "coder", "cleaner", "sw-architect", "hardender", "qa"]
TABLE_PROFILES = ["codex-only", "claude-only", "mix", "glm-max"]

# Skills that ship inside an npm package rather than skills/, so they resolve at
# runtime and must not be flagged as missing. Keyed to the package that owns them.
PACKAGED_SKILLS = {
    "ponytail": "pi-ponytail",
    "ponytail-review": "pi-ponytail",
    "ponytail-audit": "pi-ponytail",
    "ponytail-debt": "pi-ponytail",
    "ponytail-help": "pi-ponytail",
}

failures = []


def fail(msg):
    failures.append(msg)


def rel(*p):
    path = os.path.abspath(os.path.join(ROOT, *p))
    if os.path.commonpath((ROOT, path)) != ROOT:
        raise ValueError(f"path escapes repository root: {path}")
    return path


def list_dir(*p):
    try:
        return os.listdir(rel(*p))
    except OSError:
        raise


def read_file(*p):
    try:
        # pi-lens-ignore: python-path-traversal — rel() constrains paths to ROOT.
        with open(rel(*p), encoding="utf-8") as file:
            return file.read()
    except (OSError, UnicodeError):
        raise


def load_json(*p):
    try:
        return json.loads(read_file(*p))
    except json.JSONDecodeError:
        raise


def parse_int(value):
    try:
        return int(value)
    except ValueError:
        raise


def profiles():
    return {
        f[:-5]: load_json("profiles", "pi-subagents", f)
        for f in sorted(list_dir("profiles", "pi-subagents"))
        if f.endswith(".json")
    }


def tracked_skills():
    """List public skill directories; private gitignored packs stay undocumented."""
    output = subprocess.check_output(
        ["git", "-C", ROOT, "ls-files", "-z", "skills/*/SKILL.md"]
    )
    return sorted({
        path.decode().split("/")[1]
        for path in output.split(b"\0")
        if path
    })


def overrides(doc):
    return doc["subagents"]["agentOverrides"]


def check_skill_tables():
    """README skill header count and table rows match tracked skills exactly."""
    actual = tracked_skills()
    for readme in ["README.md", "README.ko.md"]:
        s = read_file(readme)
        m = re.search(r"### (?:Skills|스킬) \((\d+)\)(.*?)\n### ", s, re.S)
        if not m:
            fail(f"{readme}: no '### Skills (N)' section found")
            continue
        header = parse_int(m.group(1))
        rows = sorted(re.findall(r"^\|\s+`([^`]+)`", m.group(2), re.M))
        if header != len(actual):
            fail(f"{readme}: header says {header} skills, skills/ has {len(actual)}")
        if rows != actual:
            missing = sorted(set(actual) - set(rows))
            extra = sorted(set(rows) - set(actual))
            fail(f"{readme}: table drift — missing rows {missing}, stale rows {extra}")


def check_layout_skill_count():
    """The Layout block repeats the skill count in prose; it drifts independently."""
    actual = len(tracked_skills())
    patterns = [
        ("README.md", re.compile(r"^skills/\s+(\d+) agent skills$", re.M)),
        ("README.ko.md", re.compile(r"^skills/\s+에이전트 스킬 (\d+)개$", re.M)),
    ]
    for readme, pattern in patterns:
        s = read_file(readme)
        m = pattern.search(s)
        if not m:
            fail(f"{readme}: Layout block has no skills/ count line")
        elif parse_int(m.group(1)) != actual:
            fail(f"{readme}: Layout block says {m.group(1)} skills, skills/ has {actual}")


def check_no_frontmatter_model():
    """A `model:` in agent frontmatter outranks agentOverrides and mutes every profile."""
    pinned = []
    for f in sorted(list_dir("agents")):
        if not f.endswith(".md"):
            continue
        text = read_file("agents", f)
        head = text.split("---")[1] if "---" in text else ""
        if re.search(r"^model:", head, re.M):
            pinned.append(f)
    if pinned:
        fail(f"agents/ pin `model:` in frontmatter, which silently overrides every profile: {pinned}")


def check_referenced_skills_exist():
    """Every skill named in a profile resolves — in skills/ or an installed package."""
    have = set(list_dir("skills"))
    packages = set(load_json("settings.json")["packages"])
    docs = dict(profiles())
    docs["settings.json"] = load_json("settings.json")
    for name, doc in docs.items():
        for agent, cfg in overrides(doc).items():
            for skill in cfg.get("skills", []):
                if skill in have:
                    continue
                pkg = PACKAGED_SKILLS.get(skill)
                if pkg and f"npm:{pkg}" in packages:
                    continue
                fail(f"{name}: agent '{agent}' references skill '{skill}' which is in neither skills/ nor an installed package")


def check_agents_have_overrides():
    """Every agent is routed by settings.json, so no agent launches without a fallback chain."""
    agents = {f[:-3] for f in list_dir("agents") if f.endswith(".md")}
    ov = overrides(load_json("settings.json"))
    missing = sorted(agents - set(ov))
    if missing:
        fail(f"settings.json: agents with no override (no model, no fallback chain): {missing}")


def check_default_model_docs():
    """README default-model statements match the active settings."""
    settings = load_json("settings.json")
    expected_model = f"{settings['defaultProvider']}/{settings['defaultModel']}"
    expected_thinking = settings["defaultThinkingLevel"]
    patterns = [
        (
            "README.md",
            re.compile(r"The default model is `([^`]+)` at thinking `([^`]+)`"),
            (expected_model, expected_thinking),
        ),
        (
            "README.ko.md",
            re.compile(r"기본 모델은 사고 수준 `([^`]+)`의 `([^`]+)`(?:이)?다"),
            (expected_thinking, expected_model),
        ),
    ]
    for readme, pattern, expected in patterns:
        match = pattern.search(read_file(readme))
        if not match:
            fail(f"{readme}: no default-model statement found")
        elif match.groups() != expected:
            fail(
                f"{readme}: default model says {match.groups()}, "
                f"settings.json says {expected}"
            )


def check_recursive_rm_guards():
    """Common recursive rm forms ask, and filesystem-root targets are denied."""
    rules = load_json("configs", "permissions.json")["permission"]["bash"]

    def action(command):
        result = None
        for pattern, rule in rules.items():
            if fnmatchcase(command, pattern):
                result = rule["action"] if isinstance(rule, dict) else rule
        return result

    expectations = {
        "ask": [
            "rm -r build",
            "rm -R build",
            "rm -rf build",
            "rm -fr build",
            "rm -f -r build",
            "rm -r -f build",
            "rm --recursive build",
            "rm --force --recursive build",
        ],
        "deny": [
            "rm -rf /",
            "rm -R /",
            "rm -f -r /",
            "rm -Rf /",
            "rm --force --recursive /",
            "rm -rf --no-preserve-root /",
        ],
    }
    for expected, commands in expectations.items():
        wrong = [command for command in commands if action(command) != expected]
        if wrong:
            fail(
                f"configs/permissions.json: recursive rm commands must be "
                f"{expected}: {wrong}"
            )


def check_profile_tables():
    """README profile tables match the profile JSON cell for cell."""
    docs = profiles()
    for readme in ["README.md", "README.ko.md"]:
        s = read_file(readme)
        for gate in GATES:
            m = re.search(rf"^\| {re.escape(gate)} \|(.+)$", s, re.M)
            if not m:
                fail(f"{readme}: profile table has no row for gate '{gate}'")
                continue
            cells = [c.strip() for c in m.group(1).split("|") if c.strip()]
            if len(cells) != len(TABLE_PROFILES):
                fail(f"{readme}: gate '{gate}' has {len(cells)} cells, expected {len(TABLE_PROFILES)}")
                continue
            for prof, cell in zip(TABLE_PROFILES, cells):
                cfg = overrides(docs[prof]).get(gate)
                if not cfg:
                    fail(f"{readme}: table lists gate '{gate}' for '{prof}', but the profile has no such entry")
                    continue
                model = cfg["model"].split("/")[-1]
                # Cells abbreviate: "luna · max" for gpt-5.6-luna, "sonnet-5 · high", etc.
                stub = cell.split("·")[0].strip().replace("codex ", "")
                if stub not in model:
                    fail(f"{readme}: gate '{gate}' / '{prof}' cell says '{stub}', profile says '{model}'")


def main():
    check_skill_tables()
    check_layout_skill_count()
    check_no_frontmatter_model()
    check_referenced_skills_exist()
    check_agents_have_overrides()
    check_default_model_docs()
    check_recursive_rm_guards()
    check_profile_tables()
    if failures:
        print(f"✗ {len(failures)} doc/config mismatch(es):\n")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("✓ docs/config match — skills, model routes, profiles, and permission guards")
    return 0


if __name__ == "__main__":
    sys.exit(main())
