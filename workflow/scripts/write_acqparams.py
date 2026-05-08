#!/usr/bin/env python3
import json
from pathlib import Path


def pe_to_fsl_row(phase_encoding_direction, total_readout_time):
    mapping = {
        "i":  (1, 0, 0),
        "i-": (-1, 0, 0),
        "j":  (0, 1, 0),
        "j-": (0, -1, 0),
        "k":  (0, 0, 1),
        "k-": (0, 0, -1),
    }
    if phase_encoding_direction not in mapping:
        raise ValueError(f"Unsupported PhaseEncodingDirection: {phase_encoding_direction}")
    x, y, z = mapping[phase_encoding_direction]
    return f"{x} {y} {z} {total_readout_time}"


def load_json(path):
    with open(path, "r") as f:
        return json.load(f)


def main():
    json_01 = Path(snakemake.input.json_01)
    json_02 = Path(snakemake.input.json_02)
    out_txt = Path(snakemake.output.acqparams_txt)

    meta_01 = load_json(json_01)
    meta_02 = load_json(json_02)

    row_01 = pe_to_fsl_row(
        meta_01["PhaseEncodingDirection"],
        meta_01["TotalReadoutTime"],
    )
    row_02 = pe_to_fsl_row(
        meta_02["PhaseEncodingDirection"],
        meta_02["TotalReadoutTime"],
    )

    out_txt.parent.mkdir(parents=True, exist_ok=True)
    with open(out_txt, "w") as f:
        f.write(row_01 + "\n")
        f.write(row_02 + "\n")


if __name__ == "__main__":
    main()
