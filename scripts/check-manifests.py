#!/usr/bin/env python3
"""Check that skills on disk, manifests, registry and README agree. Exit 2 on errors."""
import json, re, sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
errors, warns = [], []

def load(p):
    try:
        return json.loads((root / p).read_text())
    except Exception as e:
        errors.append(f"{p}: {e}")

def front(p):
    m = re.match(r"---\n(.*?)\n---", p.read_text(), re.S)
    out = {}
    for line in (m.group(1) if m else "").splitlines():
        k, _, v = line.partition(":")
        if v.strip().startswith("["):
            try:
                out[k] = json.loads(v)
            except ValueError:
                errors.append(f"{p.relative_to(root)}: unparsable list in '{k}'")
        elif v.strip():
            out[k] = v.strip().strip('"')
    return out

disk = {}  # "category/slug" -> frontmatter
for f in sorted((root / "skills").glob("*/*/SKILL.md")):
    key = f"{f.parent.parent.name}/{f.parent.name}"
    disk[key] = front(f)
    if disk[key].get("name") != f.parent.name:
        errors.append(f"{key}: frontmatter name {disk[key].get('name')!r} != dir name")
    for k in ("description", "triggers"):
        if not disk[key].get(k):
            errors.append(f"{key}: missing frontmatter '{k}'")

plugin = load(".claude-plugin/plugin.json")
registry = load("skills/registry.json")
for p in ("plugin.json", "gemini-extension.json", "package.json", ".claude-plugin/marketplace.json"):
    load(p)

if plugin:
    listed = {s.removeprefix("./skills/") for s in plugin.get("skills", [])}
    for k in disk.keys() - listed: errors.append(f".claude-plugin/plugin.json: missing {k}")
    for k in listed - disk.keys(): errors.append(f".claude-plugin/plugin.json: {k} not on disk")

if registry:
    reg = {s["name"]: s for s in registry.get("skills", [])}
    for k in disk.keys() - reg.keys(): errors.append(f"registry.json: missing {k}")
    for k in reg.keys() - disk.keys(): errors.append(f"registry.json: {k} not on disk")
    for k in disk.keys() & reg.keys():
        if disk[k].get("triggers", []) != reg[k].get("triggers", []):
            errors.append(f"{k}: 'triggers' differ between SKILL.md and registry.json")
        md, rg = set(disk[k].get("conflicts_with", [])), set(reg[k].get("conflicts_with", []))
        if md - rg: errors.append(f"{k}: SKILL.md conflicts_with not in registry.json: {sorted(md - rg)}")
        if rg - md: warns.append(f"{k}: registry.json has extra conflicts_with: {sorted(rg - md)}")
    for pair, c in registry.get("conflict_matrix", {}).items():
        for t in ("thesis_a", "thesis_b"):
            s = c.get(t, {}).get("skill", "")
            # non-skill positions (e.g. "Microservices / Cloud-Native") are allowed
            if "/" in s and s.split("/")[0] in {k.split("/")[0] for k in disk} and s not in disk:
                errors.append(f"registry.json conflict '{pair}': unknown skill {s}")

for k, fm in disk.items():
    for c in fm.get("conflicts_with", []):
        if c not in disk: errors.append(f"{k}: conflicts_with unknown skill {c}")

readme = (root / "README.md").read_text()
for k in disk:
    if k.split("/")[1] not in readme: warns.append(f"README.md: no mention of {k}")

versions = {}
for p in ("package.json", "plugin.json", "gemini-extension.json", ".claude-plugin/plugin.json"):
    try: versions[p] = json.loads((root / p).read_text()).get("version")
    except Exception: pass
if len(set(versions.values())) > 1: warns.append(f"version drift: {versions}")

for w in warns: print("warn:", w, file=sys.stderr)
for e in errors: print("error:", e, file=sys.stderr)
print(f"{len(disk)} skills checked: {len(errors)} errors, {len(warns)} warnings")
sys.exit(2 if errors else 0)
