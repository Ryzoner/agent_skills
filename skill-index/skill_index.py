#!/usr/bin/env python3
"""Skill index: keep skill descriptions out of the context and route through INDEX.md.

Commands:
  status          measure what is registered now and what would be after
  sync [--apply]  move skills out of the scanned dirs into the library (dry-run by default)
  build           generate INDEX.md and groups/*.md from the library and groups.json
  check           list skills with no group, duplicates, empty groups
  install         copy router skill, script and manifest to the device, then sync + build
  revert          undo the last applied sync
Stdlib only, Python 3.8+. SKILL_INDEX_HOME overrides the home dir (tests).
"""
import argparse, fnmatch, json, os, re, shutil, sys, time
from pathlib import Path

HOME = Path(os.environ.get("SKILL_INDEX_HOME") or Path.home())
AGENTS = HOME / ".agents"
LIB = AGENTS / "skill-library"
IDX = AGENTS / "skill-index"
SCAN = [AGENTS / "skills", HOME / ".claude" / "skills", HOME / ".config" / "agents" / "skills"]
HERE = Path(__file__).resolve().parent
MANIFEST = HERE / "groups.json"


def manifest():
    return json.loads(MANIFEST.read_text(encoding="utf-8"))


def meta(skill_dir):
    p = Path(skill_dir) / "SKILL.md"
    if not p.is_file():
        return None
    t = p.read_text(encoding="utf-8", errors="ignore")
    m = re.match(r"---\r?\n(.*?)\r?\n---", t, re.S)
    fm = m.group(1) if m else ""
    n = re.search(r"^name:\s*(.*)$", fm, re.M)
    d = re.search(r"^description:\s*(.*(?:\n[ \t]+.*)*)", fm, re.M)
    desc = re.sub(r"\s+", " ", d.group(1)).strip(" >|\"'") if d else ""
    return (n.group(1).strip(" \"'") if n else Path(skill_dir).name), desc


def match(name, patterns):
    return any(fnmatch.fnmatch(name, p) for p in patterns)


def is_registered(name, man):
    return match(name, man.get("registered", []))


def group_of(name, man):
    for gid, g in man["groups"].items():
        if match(name, g["skills"]):
            return gid
    return None


def summary(desc, limit=150):
    desc = desc.strip()
    cut = re.search(r"(?<=[.!?])\s", desc[40:])
    if cut:
        desc = desc[: 40 + cut.start()]
    return desc if len(desc) <= limit else desc[: limit - 1].rstrip() + "…"


def tokens(chars):
    return chars // 4


def registered_cost(dirs):
    seen, total = set(), 0
    for d in dirs:
        if not d.is_dir():
            continue
        for e in sorted(d.iterdir()):
            m = meta(e) if (e / "SKILL.md").is_file() else None
            if m and e.name not in seen:
                seen.add(e.name)
                total += len(m[0]) + len(m[1]) + 20
    return len(seen), total


def plan_sync(man):
    ops, claimed, stamp = [], set(), int(time.time())
    for i, d in enumerate(SCAN):
        if not d.is_dir():
            continue
        for e in sorted(d.iterdir()):
            if e.name.startswith(".") or is_registered(e.name, man):
                continue
            if e.is_symlink():
                ops.append({"op": "unlink", "link": str(e), "target": os.readlink(e)})
            elif e.is_dir():
                dest, dups = LIB / e.name, IDX / "duplicates"
                if e.name in claimed or (dest.exists() and i != 0):
                    ops.append({"op": "move", "from": str(e), "to": str(dups / ("%d-%s-%d" % (i, e.name, stamp))), "note": "duplicate"})
                elif dest.exists():
                    ops.append({"op": "move", "from": str(dest), "to": str(dups / ("replaced-%d-%s" % (stamp, e.name))), "note": "older library copy"})
                    ops.append({"op": "move", "from": str(e), "to": str(dest)})
                    claimed.add(e.name)
                else:
                    ops.append({"op": "move", "from": str(e), "to": str(dest)})
                    claimed.add(e.name)
    return ops


def ensure_links(man):
    """Registered skills must be visible to Claude Code: link them into ~/.claude/skills."""
    src, dst = AGENTS / "skills", HOME / ".claude" / "skills"
    if not src.is_dir() or not (HOME / ".claude").is_dir():
        return 0
    dst.mkdir(parents=True, exist_ok=True)
    made = 0
    for e in sorted(src.iterdir()):
        if e.is_dir() and (e / "SKILL.md").is_file() and is_registered(e.name, man) and not (dst / e.name).exists():
            try:
                os.symlink(os.path.relpath(e, dst), dst / e.name)
            except OSError:
                shutil.copytree(e, dst / e.name)
            made += 1
    return made


def cmd_status(_):
    man = manifest()
    n_ag, c_ag = registered_cost([AGENTS / "skills"])
    n_cl, c_cl = registered_cost([HOME / ".claude" / "skills"])
    reg = [e.name for e in (AGENTS / "skills").iterdir()] if (AGENTS / "skills").is_dir() else []
    keep = [r for r in reg if is_registered(r, man)]
    print(f"registered in ~/.agents/skills (Zed and others): {n_ag} skills, ~{tokens(c_ag)} tokens of name+description")
    print(f"registered in ~/.claude/skills (Claude Code):     {n_cl} skills, ~{tokens(c_cl)} tokens")
    print(f"library now: {len([e for e in LIB.iterdir()]) if LIB.is_dir() else 0} entries")
    print(f"stay registered after sync: {sorted(keep) or '(none present yet; router is added by install)'}")
    ops = plan_sync(man)
    print("pending sync:", {k: sum(o['op'] == k for o in ops) for k in ("move", "unlink")})


def cmd_sync(a):
    man = manifest()
    ops = plan_sync(man)
    for o in ops:
        print(o["op"].ljust(8), o.get("from") or o.get("link"), "->", o.get("to") or o["target"]) if a.verbose else None
    counts = {k: sum(o["op"] == k for o in ops) for k in ("move", "unlink")}
    counts["duplicates_backed_up"] = sum(1 for o in ops if o.get("note"))
    print("plan:", counts)
    if not a.apply:
        print("dry-run: nothing changed. Re-run with --apply.")
        return
    LIB.mkdir(parents=True, exist_ok=True)
    IDX.mkdir(parents=True, exist_ok=True)
    done = []
    for o in ops:
        if o["op"] == "move":
            Path(o["to"]).parent.mkdir(parents=True, exist_ok=True)
            shutil.move(o["from"], o["to"])
            done.append(o)
        elif o["op"] == "unlink":
            os.unlink(o["link"])
            done.append(o)
    if done:
        j = IDX / ("journal-%d.json" % int(time.time()))
        j.write_text(json.dumps(done, indent=1), encoding="utf-8")
        print(f"applied {len(done)} operations; journal: {j}")
    print(f"linked {ensure_links(man)} registered skills into ~/.claude/skills")


def cmd_revert(_):
    js = sorted(IDX.glob("journal-*.json"))
    if not js:
        sys.exit("no journal to revert")
    ops = json.loads(js[-1].read_text(encoding="utf-8"))
    for o in reversed(ops):
        if o["op"] == "move":
            shutil.move(o["to"], o["from"])
        elif o["op"] == "unlink":
            os.symlink(o["target"], o["link"])
    js[-1].rename(js[-1].with_suffix(".reverted"))
    print(f"reverted {len(ops)} operations from {js[-1].name}")


def library_skills(man):
    found = {}
    for d in [LIB, AGENTS / "skills"]:
        if d.is_dir():
            for e in sorted(d.iterdir()):
                m = meta(e) if e.is_dir() else None
                if m and e.name not in found:
                    found[e.name] = {"desc": m[1], "path": e, "registered": d != LIB or is_registered(e.name, man)}
    return found


def cmd_build(_):
    man = manifest()
    skills = library_skills(man)
    by_group = {gid: [] for gid in man["groups"]}
    by_group["unsorted"] = []
    for name in skills:
        by_group[group_of(name, man) or "unsorted"].append(name)
    (IDX / "groups").mkdir(parents=True, exist_ok=True)
    for old in (IDX / "groups").glob("*.md"):
        old.unlink()
    over = man.get("overrides", {})
    lib_ref = "~/.agents/skill-library"
    lines = ["# Skill index", "",
             "Skills are NOT registered, they live in `%s/<name>/SKILL.md`. Route: pick a topic below, read its group file, "
             "read the chosen SKILL.md fully, follow it, tell the user `Скиллы: a, b`. Skip for trivial chat." % lib_ref, "",
             "## Cross-cutting (check on every task)", ""]
    for r in man.get("cross_cutting", []):
        lines.append("- %s → %s" % (r["when"], ", ".join(r["skills"])))
    lines += ["", "## Topics", ""]
    for gid, g in man["groups"].items():
        names = by_group[gid]
        if not names:
            continue
        lines.append("- **%s** (%d): %s → `groups/%s.md`" % (gid, len(names), g["about"], gid))
        body = ["# %s" % gid, "", g["about"], "",
                "Read `%s/<name>/SKILL.md` for the skills that fit. Registered skills are marked (reg)." % lib_ref, ""]
        for n in sorted(names):
            tag = " (reg)" if skills[n]["registered"] else ""
            body.append("- **%s**%s: %s" % (n, tag, over.get(n) or summary(skills[n]["desc"])))
        (IDX / "groups" / ("%s.md" % gid)).write_text("\n".join(body) + "\n", encoding="utf-8")
    if by_group["unsorted"]:
        lines.append("- **unsorted** (%d): not yet assigned to a group → `groups/unsorted.md`" % len(by_group["unsorted"]))
        body = ["# unsorted", "", "Assign these in groups.json."] + [
            "- **%s**: %s" % (n, summary(skills[n]["desc"])) for n in sorted(by_group["unsorted"])]
        (IDX / "groups" / "unsorted.md").write_text("\n".join(body) + "\n", encoding="utf-8")
    text = "\n".join(lines) + "\n"
    (IDX / "INDEX.md").write_text(text, encoding="utf-8")
    print(f"built INDEX.md ({len(text)} chars, ~{tokens(len(text))} tokens) and "
          f"{len(list((IDX / 'groups').glob('*.md')))} group files for {len(skills)} skills; unsorted: {len(by_group['unsorted'])}")


def cmd_check(_):
    man = manifest()
    skills = library_skills(man)
    un = [n for n in skills if not group_of(n, man)]
    print("unassigned:", un or "none")
    multi = [n for n in skills if sum(match(n, g["skills"]) for g in man["groups"].values()) > 1]
    print("in more than one group (first wins):", multi or "none")
    for gid, g in man["groups"].items():
        if not any(match(n, g["skills"]) for n in skills):
            print("empty on this device:", gid)


def cmd_install(a):
    man = manifest()
    IDX.mkdir(parents=True, exist_ok=True)
    for f in ("skill_index.py", "groups.json"):
        shutil.copy2(HERE / f, IDX / f)
    router = AGENTS / "skills" / "skill-router"
    if router.exists():
        shutil.rmtree(router)
    shutil.copytree(HERE / "skill-router", router)
    link = HOME / ".claude" / "skills" / "skill-router"
    if (HOME / ".claude").is_dir():
        link.parent.mkdir(parents=True, exist_ok=True)
        if link.is_symlink() or link.exists():
            link.unlink() if link.is_symlink() else shutil.rmtree(link)
        try:
            os.symlink(os.path.relpath(router, link.parent), link)
        except OSError:
            shutil.copytree(router, link)
    print("router installed")
    a.apply = True
    a.verbose = False
    cmd_sync(a)
    cmd_build(a)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    for n, f in (("status", cmd_status), ("build", cmd_build), ("check", cmd_check), ("revert", cmd_revert), ("install", cmd_install)):
        sub.add_parser(n).set_defaults(fn=f)
    s = sub.add_parser("sync")
    s.add_argument("--apply", action="store_true")
    s.add_argument("-v", "--verbose", action="store_true")
    s.set_defaults(fn=cmd_sync)
    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
