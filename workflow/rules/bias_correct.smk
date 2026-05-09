import os


MRTRIX_DEFAULT_NTHREADS = config["mrtrix"].get("default_nthreads", 1)
DWIBIASCORRECT_NTHREADS = config["mrtrix"].get(
    "dwibiascorrect_nthreads", MRTRIX_DEFAULT_NTHREADS
)


rule bias_correct_dwi:
    input:
        dwi=rules.convert_eddy_to_mif.output.mif,
        mask=rules.make_preproc_mask.output.mif,
    output:
        mif=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-preproc_dwi.mif"
        ),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "bias_correct_dwi.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "bias_correct_dwi.tsv")
    threads:
        DWIBIASCORRECT_NTHREADS
    container:
        config["singularity"]["mrtrix"]
    params:
        ants_bin=config["software"]["ants"].get("bin", "")
    shell:
        r"""
        mkdir -p "$(dirname "{output.mif}")"
        mkdir -p "$(dirname "{log}")"
    
        export PATH="{params.ants_bin}:$PATH"
    
        dwibiascorrect ants \
          -nthreads {threads} \
          -mask "{input.mask}" \
          "{input.dwi}" "{output.mif}" \
          > "{log}" 2>&1
        """
