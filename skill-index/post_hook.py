#!/usr/bin/env python3
"""PostToolUse hook (Bash): after `skills add/update/remove`, move new skills into the library and rebuild the index."""
import argparse, contextlib, io, json, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import skill_index as si  # noqa: E402

TRIGGER = re.compile(r"\bskills\s+(add|update|upgrade|remove)\b")


def names():
    return {p.name for p in si.LIB.iterdir()} if si.LIB.is_dir() else set()


def main():
    raw = sys.stdin.buffer.read().decode("utf-8", errors="ignore")
    try:
        cmd = json.loads(raw).get("tool_input", {}).get("command", "")
    except Exception:
        return
    if not TRIGGER.search(cmd):
        return
    before = names()
    ns = argparse.Namespace(apply=True, verbose=False)
    with contextlib.redirect_stdout(io.StringIO()):
        si.cmd_sync(ns)
        si.cmd_build(ns)
    man = si.manifest()
    new = sorted(names() - before)
    unsorted = sorted(n for n in si.library_skills(man) if not si.group_of(n, man))
    if not new and not unsorted:
        return
    msg = "skill-index: скиллы перенесены в библиотеку, индекс пересобран."
    if new:
        msg += " Новые: %s." % ", ".join(new)
    if unsorted:
        msg += (" Без группы (тема unsorted): %s. Назначь группу по скиллу skill-manager: "
                "python ~/.agents/skill-index/skill_index.py assign <скилл>." % ", ".join(unsorted))
    out = {"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}
    sys.stdout.buffer.write(json.dumps(out, ensure_ascii=False).encode("utf-8"))


if __name__ == "__main__":
    main()
