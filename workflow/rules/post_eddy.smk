import os

EDDY_QUAD_EXE = config["software"]["fsl"].get("eddy_quad_exe", "eddy_quad")



rule eddy_quad_qc:
    input:
        eddy_nii=rules.run_eddy.output.nii,
        eddy_bvec=rules.run_eddy.output.bvec,
        eddy_bval=rules.run_eddy.output.bval,
        mask=rules.make_eddy_mask.output.mask,
        acqparams=rules.write_acqparams.output.acqparams_txt,
        index_txt=rules.write_eddy_index.output.index_txt,
    output:
        qc_dir=directory(
            os.path.join(
                QCDIR,
                "sub-{subject}",
                "eddy_quad"
            )
        ),
    params:
        eddy_base=lambda wildcards: os.path.join(
            OUTDIR,
            f"sub-{wildcards.subject}",
            "dwi",
            f"sub-{wildcards.subject}_desc-eddy_dwi_work",
        ),
        eddy_quad_exe=EDDY_QUAD_EXE,
    log:
        os.path.join(LOGDIR, "sub-{subject}", "eddy_quad_qc.log")
    container:
        config["singularity"]["fsl"]
    shell:
        r"""
        mkdir -p "$(dirname "{log}")"
        mkdir -p "$(dirname "{output.qc_dir}")"
        rm -rf "{output.qc_dir}"

        "{params.eddy_quad_exe}" "{params.eddy_base}" \
          -idx "{input.index_txt}" \
          -par "{input.acqparams}" \
          -m "{input.mask}" \
          -b "{input.eddy_bval}" \
          -g "{input.eddy_bvec}" \
          -o "{output.qc_dir}" \
          -v \
          > "{log}" 2>&1
        """

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
          -datatype bit \
          > "{log}" 2>&1

        mrconvert -nthreads {threads} \
          "{output.mif}" "{output.nii}" \
          >> "{log}" 2>&1
        """
