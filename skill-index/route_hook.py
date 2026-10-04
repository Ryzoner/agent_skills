#!/usr/bin/env python3
"""UserPromptSubmit hook: suggest skill-index topics for the prompt, silent when nothing matches.

Reads the hook JSON from stdin, matches the prompt against `keywords` (regex) of each group and of each
cross-cutting rule in groups.json next to this file, prints additionalContext for Claude Code.
"""
import json, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
MAN = {}


def hits(text, patterns):
    return sum(1 for p in patterns if re.search(p, text, re.I))


def suggest(prompt, man):
    text = re.sub(r"<(system-reminder|local-command-[a-z]+|command-[a-z]+)>.*?</\1>", " ", prompt, flags=re.S).lower()
    if any(re.search(p, text, re.I) for p in man.get("skip", [])):
        return [], []
    scored = sorted(((hits(text, g.get("keywords", [])), gid) for gid, g in man["groups"].items()), reverse=True)
    topics = [gid for n, gid in scored if n > 0][:2]
    cross = []
    for r in man.get("cross_cutting", []):
        if hits(text, r.get("keywords", [])):
            cross += [s for s in r["skills"] if s not in cross]
    return topics, cross


def message(topics, cross):
    parts = ["Маршрутизация скиллов (подсказка хука по словам запроса)."]
    if topics:
        files = ", ".join("~/.agents/skill-index/groups/%s.md" % t for t in topics)
        parts.append("Похоже на темы: %s. Перед ответом прочитай %s, выбери до 3 скиллов, прочитай их SKILL.md и следуй им."
                     % (", ".join(topics), files))
    if cross:
        parts.append("По словам запроса подходят сквозные: %s." % ", ".join(cross))
    if topics:
        rules = "; ".join(r.get("short", "") for r in MAN.get("cross_cutting", []) if r.get("short"))
        parts.append("Сквозные правила, проверь всегда: %s." % rules)
    parts.append("В ответе строка `Скиллы: a, b (ещё подходят: c)`. Если подсказка не по делу, проигнорируй её.")
    return " ".join(parts)


def main():
    raw = sys.stdin.buffer.read().decode("utf-8", errors="ignore")
    try:
        prompt = json.loads(raw).get("prompt", "")
    except Exception:
        return
    global MAN
    man = MAN = json.loads((HERE / "groups.json").read_text(encoding="utf-8"))
    topics, cross = suggest(prompt, man)
    if not topics and not cross:
        return
    out = {"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": message(topics, cross)}}
    sys.stdout.buffer.write(json.dumps(out, ensure_ascii=False).encode("utf-8"))


if __name__ == "__main__":
    main()
