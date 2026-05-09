#!/usr/bin/env python3
import json
import os
import subprocess
import tempfile
from pathlib import Path


def run(cmd, log_path):
    with open(log_path, "a") as logf:
        subprocess.run(cmd, check=True, stdout=logf, stderr=logf)


def main():
    roles_json = Path(snakemake.input.roles_json)
    mif_01 = Path(snakemake.input.mif_01)
    mif_02 = Path(snakemake.input.mif_02)
    out_mask = Path(snakemake.output.mask)
    log_path = Path(snakemake.log[0])
    threads = int(snakemake.threads)

    out_mask.parent.mkdir(parents=True, exist_ok=True)
    log_path.parent.mkdir(parents=True, exist_ok=True)

    with open(roles_json, "r") as f:
        roles = json.load(f)

    main_run = roles["main_run"]
    if main_run == "01":
        src_mif = mif_01
    elif main_run == "02":
        src_mif = mif_02
    else:
        raise ValueError(f"Invalid main_run: {main_run}")

    if log_path.exists():
        log_path.unlink()

    fd, tmp_name = tempfile.mkstemp(suffix=".mif")
    os.close(fd)
    os.unlink(tmp_name)
    tmp_mask = Path(tmp_name)

    try:
        run(
            [
                "dwi2mask",
                "-force",
                "-nthreads",
                str(threads),
                str(src_mif),
                str(tmp_mask),
            ],
            log_path,
        )

        run(
            [
                "mrconvert",
                "-force",
                "-nthreads",
                str(threads),
                str(tmp_mask),
                str(out_mask),
            ],
            log_path,
        )
    finally:
        if tmp_mask.exists():
            tmp_mask.unlink()


if __name__ == "__main__":
    main()
