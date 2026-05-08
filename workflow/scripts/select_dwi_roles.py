#!/usr/bin/env python3
import json
from pathlib import Path


def load_json(path):
    with open(path, "r") as f:
        return json.load(f)


def get_ndim_and_nvols(meta):
    shape = meta.get("dcmmeta_shape", [])
    ndim = len(shape)
    nvols = shape[3] if ndim >= 4 else 1
    return ndim, nvols


def main():
    in_json_01 = Path(snakemake.input.json_01)
    in_json_02 = Path(snakemake.input.json_02)
    out_json = Path(snakemake.output.roles_json)

    meta_01 = load_json(in_json_01)
    meta_02 = load_json(in_json_02)

    ndim_01, nvols_01 = get_ndim_and_nvols(meta_01)
    ndim_02, nvols_02 = get_ndim_and_nvols(meta_02)

    pe_01 = meta_01.get("PhaseEncodingDirection")
    pe_02 = meta_02.get("PhaseEncodingDirection")
    trt_01 = meta_01.get("TotalReadoutTime")
    trt_02 = meta_02.get("TotalReadoutTime")

    if pe_01 is None or pe_02 is None:
        raise ValueError("Missing PhaseEncodingDirection in one or both DWI JSON files.")

    if trt_01 is None or trt_02 is None:
        raise ValueError("Missing TotalReadoutTime in one or both DWI JSON files.")

    # Choose main DWI as the 4D series with the most volumes.
    if ndim_01 >= 4 and (ndim_02 < 4 or nvols_01 >= nvols_02):
        main_run = "01"
        support_run = "02"
        main_meta = meta_01
        support_meta = meta_02
    elif ndim_02 >= 4:
        main_run = "02"
        support_run = "01"
        main_meta = meta_02
        support_meta = meta_01
    else:
        raise ValueError("Neither run appears to be a 4D DWI series.")

    roles = {
        "main_run": main_run,
        "support_run": support_run,
        "main_phase_encoding_direction": main_meta["PhaseEncodingDirection"],
        "support_phase_encoding_direction": support_meta["PhaseEncodingDirection"],
        "main_total_readout_time": main_meta["TotalReadoutTime"],
        "support_total_readout_time": support_meta["TotalReadoutTime"],
        "main_shape": main_meta.get("dcmmeta_shape"),
        "support_shape": support_meta.get("dcmmeta_shape"),
    }

    out_json.parent.mkdir(parents=True, exist_ok=True)
    with open(out_json, "w") as f:
        json.dump(roles, f, indent=2)


if __name__ == "__main__":
    main()
