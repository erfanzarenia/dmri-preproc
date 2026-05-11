#!/usr/bin/env python3
import json
import shutil
import subprocess
import sys
from pathlib import Path

import yaml


def safe_run(cmd, cwd=None):
    try:
        result = subprocess.run(
            cmd,
            check=True,
            capture_output=True,
            text=True,
            cwd=cwd,
        )
        return result.stdout.strip()
    except Exception:
        return None


def copy_if_exists(src: Path, dst: Path):
    if src.is_file():
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)


def copy_tree_if_exists(src: Path, dst: Path, ignore=None):
    if src.exists() and src.is_dir():
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst, ignore=ignore)


def main():
    output_dir = Path(snakemake.params.output_dir)
    repo_root = Path(snakemake.params.repo_root)
    metadata_dir = Path(snakemake.output.metadata_dir)

    metadata_dir.mkdir(parents=True, exist_ok=True)

    resolved_config_path = metadata_dir / "config.yaml"
    with open(resolved_config_path, "w") as f:
        yaml.safe_dump(dict(snakemake.config), f, sort_keys=False)

    snakemake_version = safe_run(["snakemake", "--version"])
    with open(metadata_dir / "snakemake_version.txt", "w") as f:
        f.write((snakemake_version or "unknown") + "\n")

    python_version = sys.version.replace("\n", " ")
    with open(metadata_dir / "python_version.txt", "w") as f:
        f.write(python_version + "\n")

    git_commit = safe_run(["git", "rev-parse", "HEAD"], cwd=repo_root)
    with open(metadata_dir / "git_commit.txt", "w") as f:
        f.write((git_commit or "unknown") + "\n")

    git_status = safe_run(["git", "status", "--short"], cwd=repo_root)
    with open(metadata_dir / "git_status.txt", "w") as f:
        f.write((git_status or "") + ("\n" if git_status else ""))

    copy_if_exists(repo_root / "run.sh", metadata_dir / "run.sh")
    copy_if_exists(repo_root / "workflow" / "Snakefile", metadata_dir / "workflow" / "Snakefile")
    copy_tree_if_exists(repo_root / "workflow" / "rules", metadata_dir / "workflow" / "rules")
    copy_tree_if_exists(repo_root / "scripts", metadata_dir / "scripts")

    manifest = {
        "output_dir": str(output_dir),
        "metadata_dir": str(metadata_dir),
        "subjects": snakemake.config.get("participant_label", "all"),
    }
    with open(metadata_dir / "manifest.json", "w") as f:
        json.dump(manifest, f, indent=2)


if __name__ == "__main__":
    main()
