#!/usr/bin/env python3
import json
import shutil
import subprocess
from pathlib import Path


def run(cmd, log_path):
    with open(log_path, "a") as logf:
        subprocess.run(cmd, check=True, stdout=logf, stderr=logf)


def main():
    roles_json = Path(snakemake.input.roles_json)
    mif_01 = Path(snakemake.input.mif_01)
    mif_02 = Path(snakemake.input.mif_02)
    json_01 = Path(snakemake.input.json_01)
    json_02 = Path(snakemake.input.json_02)

    out_nii = Path(snakemake.output.nii)
    out_bvec = Path(snakemake.output.bvec)
    out_bval = Path(snakemake.output.bval)
    out_json = Path(snakemake.output.json)

    log_path = Path(snakemake.log[0])
    threads = int(snakemake.threads)

    out_nii.parent.mkdir(parents=True, exist_ok=True)
    log_path.parent.mkdir(parents=True, exist_ok=True)

    with open(roles_json, "r") as f:
        roles = json.load(f)

    main_run = roles["main_run"]

    if main_run == "01":
        src_mif = mif_01
        src_json = json_01
    elif main_run == "02":
        src_mif = mif_02
        src_json = json_02
    else:
        raise ValueError(f"Invalid main_run: {main_run}")

    if log_path.exists():
        log_path.unlink()

    run(
        [
            "mrconvert",
            "-nthreads",
            str(threads),
            str(src_mif),
            str(out_nii),
            "-export_grad_fsl",
            str(out_bvec),
            str(out_bval),
        ],
        log_path,
    )

    shutil.copyfile(src_json, out_json)


if __name__ == "__main__":
    main()
