import os


MRTRIX_DEFAULT_NTHREADS = config["mrtrix"].get("default_nthreads", 1)
MRCONVERT_NTHREADS = config["mrtrix"].get("mrconvert_nthreads", MRTRIX_DEFAULT_NTHREADS)
DWI2MASK_NTHREADS = config["mrtrix"].get("dwi2mask_nthreads", MRTRIX_DEFAULT_NTHREADS)


rule convert_eddy_to_mif:
    input:
        nii=rules.run_eddy.output.nii,
        bvec=rules.run_eddy.output.bvec,
        bval=rules.run_eddy.output.bval,
    output:
        mif=temp(
            os.path.join(
                OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-eddy_dwi.mif"
            )
        ),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "convert_eddy_to_mif.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "convert_eddy_to_mif.tsv")
    threads:
        MRCONVERT_NTHREADS
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.mif}")"
        mkdir -p "$(dirname "{log}")"

        mrconvert -nthreads {threads} \
          "{input.nii}" "{output.mif}" \
          -fslgrad "{input.bvec}" "{input.bval}" \
          > "{log}" 2>&1
        """


rule make_preproc_mask:
    input:
        mif=rules.convert_eddy_to_mif.output.mif,
    output:
        mif=temp(
            os.path.join(
                OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-brain_mask.mif"
            )
        ),
        nii=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-brain_mask.nii.gz"
        ),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "make_preproc_mask.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "make_preproc_mask.tsv")
    threads:
        DWI2MASK_NTHREADS
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.mif}")"
        mkdir -p "$(dirname "{log}")"

        dwi2mask -nthreads {threads} "{input.mif}" "{output.mif}" > "{log}" 2>&1
        mrconvert -nthreads {threads} "{output.mif}" "{output.nii}" >> "{log}" 2>&1
        """
