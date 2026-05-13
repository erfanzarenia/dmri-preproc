import os


ANTS_BIN = config.get("software", {}).get("ants", {}).get(
    "bin",
    config.get("software", {}).get("ants_bin", ""),
)


rule bias_correct_dwi:
    input:
        dwi=rules.convert_eddy_to_mif.output.mif,
        mask=rules.convert_eddy_mask_to_mif.output.mif,
    output:
        mif=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-preproc_dwi.mif"
        ),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "bias_correct_dwi.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "bias_correct_dwi.tsv")
    threads:
        config["threads"]["mrtrix"].get("dwibiascorrect", config["threads"].get("default", 1))
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.mif}")"
        mkdir -p "$(dirname "{log}")"

        export PATH="{ANTS_BIN}:$PATH"

        dwibiascorrect ants \
          -nthreads {threads} \
          -mask "{input.mask}" \
          "{input.dwi}" "{output.mif}" \
          > "{log}" 2>&1
        """
