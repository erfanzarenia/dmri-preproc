#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path


def main():
    roles_json = Path(snakemake.input.roles_json)
    preeddy_nii = Path(snakemake.input.preeddy_nii)
    out_index = Path(snakemake.output.index_txt)
    log_path = Path(snakemake.log[0])

    out_index.parent.mkdir(parents=True, exist_ok=True)
    log_path.parent.mkdir(parents=True, exist_ok=True)

    with open(roles_json, "r") as f:
        roles = json.load(f)

    main_run = roles["main_run"]
    if main_run == "01":
        acq_row = "1"
    elif main_run == "02":
        acq_row = "2"
    else:
        raise ValueError(f"Invalid main_run: {main_run}")

    result = subprocess.check_output(
        ["mrinfo", "-size", str(preeddy_nii)],
        text=True,
    ).strip()
    nvols = int(result.split()[3])

    with open(out_index, "w") as f:
        f.write(" ".join([acq_row] * nvols) + "\n")

    with open(log_path, "w") as f:
        f.write(f"Wrote eddy index with nvols={nvols} and acq_row={acq_row}\n")


if __name__ == "__main__":
    main()
