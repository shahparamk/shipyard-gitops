"""Validate the GitOps repo: Argo apps parse, third-party charts are pinned, the image tag is a SHA."""
import glob
import re
import sys

import yaml

EXACT_VERSION = re.compile(r"^v?\d+\.\d+\.\d+$")  # 1.13.1 or v1.21.2; not main/latest/ranges
COMMIT_SHA = re.compile(r"^[0-9a-f]{40}$")

errors = []
checked = 0

for path in sorted(glob.glob("argocd/**/*.yaml", recursive=True)):
    try:
        with open(path, encoding="utf-8") as f:
            docs = [d for d in yaml.safe_load_all(f) if d]
    except yaml.YAMLError as e:
        errors.append(f"{path}: invalid YAML: {e}")
        continue
    for doc in docs:
        if doc.get("kind") != "Application":
            continue
        checked += 1
        name = doc.get("metadata", {}).get("name", "?")
        source = doc.get("spec", {}).get("source", {})
        if "chart" in source:  # third-party Helm chart: must be pinned to an exact version
            rev = str(source.get("targetRevision", ""))
            if not EXACT_VERSION.match(rev):
                errors.append(f"{path}: app '{name}' chart '{source['chart']}' targetRevision '{rev}' is not an exact version")

with open("envs/dev/values-orders.yaml", encoding="utf-8") as f:
    values = yaml.safe_load(f) or {}
tag = str((values.get("image") or {}).get("tag", ""))
if not COMMIT_SHA.match(tag):
    errors.append(f"envs/dev/values-orders.yaml: image.tag '{tag}' must be a full 40-character commit SHA")

print(f"Checked {checked} Argo Applications and the dev image tag.")
if errors:
    print("\n".join(f"ERROR: {e}" for e in errors))
    sys.exit(1)
print("All checks passed.")