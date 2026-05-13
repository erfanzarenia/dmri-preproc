import os


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
        config["threads"]["mrtrix"].get("mrconvert", config["threads"].get("default", 1))
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


rule convert_eddy_mask_to_mif:
    input:
        mask=rules.make_eddy_mask.output.mask,
        dwi=rules.convert_eddy_to_mif.output.mif,
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
        os.path.join(LOGDIR, "sub-{subject}", "convert_eddy_mask_to_mif.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "convert_eddy_mask_to_mif.tsv")
    threads:
        config["threads"]["mrtrix"].get("mrconvert", config["threads"].get("default", 1))
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.mif}")"
        mkdir -p "$(dirname "{log}")"

        mrconvert -nthreads {threads} \
          "{input.mask}" "{output.mif}" \
          -template "{input.dwi}" \
          -datatype bit \
          > "{log}" 2>&1

        mrconvert -nthreads {threads} \
          "{output.mif}" "{output.nii}" \
          >> "{log}" 2>&1
        """
