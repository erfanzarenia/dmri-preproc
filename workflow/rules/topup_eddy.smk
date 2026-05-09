import os


MRTRIX_DEFAULT_NTHREADS = config["mrtrix"].get("default_nthreads", 1)
DWI2MASK_NTHREADS = config["mrtrix"].get("dwi2mask_nthreads", MRTRIX_DEFAULT_NTHREADS)
MRCONVERT_NTHREADS = config["mrtrix"].get("mrconvert_nthreads", MRTRIX_DEFAULT_NTHREADS)

TOPUP_CONFIG = config["fsl"].get("topup_config", "b02b0.cnf")
EDDY_NTHREADS = config["fsl"].get("eddy_nthreads", 1)
EDDY_EXE = config["fsl"].get("eddy_exe", "/software/fsl/6.0.4/bin/eddy_cpu")


rule export_topup_b0pair_nii:
    input:
        mif=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_b0pair.mif"
        ),
    output:
        nii=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_b0pair.nii.gz"
        ),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "export_topup_b0pair_nii.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "export_topup_b0pair_nii.tsv")
    threads:
        MRCONVERT_NTHREADS
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.nii}")"
        mkdir -p "$(dirname "{log}")"

        mrconvert -nthreads {threads} "{input.mif}" "{output.nii}" > "{log}" 2>&1
        """


rule run_topup:
    input:
        b0pair_nii=rules.export_topup_b0pair_nii.output.nii,
        acqparams=rules.write_acqparams.output.acqparams_txt,
    output:
        corrected_b0pair=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_b0pair_corrected.nii.gz"
        ),
        fieldmap=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_fieldmap.nii.gz"
        ),
        fieldcoef=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_fieldcoef.nii.gz"
        ),
        movpar=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_movpar.txt"
        ),
    params:
        topup_base=lambda wildcards: os.path.join(
            OUTDIR,
            f"sub-{wildcards.subject}",
            "dwi",
            f"sub-{wildcards.subject}_desc-topup",
        ),
        topup_config=TOPUP_CONFIG,
    log:
        os.path.join(LOGDIR, "sub-{subject}", "run_topup.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "run_topup.tsv")
    container:
        config["singularity"]["fsl"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.corrected_b0pair}")"
        mkdir -p "$(dirname "{log}")"

        topup \
          --imain="{input.b0pair_nii}" \
          --datain="{input.acqparams}" \
          --config="{params.topup_config}" \
          --out="{params.topup_base}" \
          --iout="{output.corrected_b0pair}" \
          --fout="{output.fieldmap}" \
          > "{log}" 2>&1
        """


rule export_main_dwi_for_eddy:
    input:
        roles_json=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-dwiroles.json"
        ),
        mif_01=rules.mrdegibbs_run_01.output.mif,
        mif_02=rules.mrdegibbs_run_02.output.mif,
        json_01=rules.import_dwi_run_01.output[3],
        json_02=rules.import_dwi_run_02.output[3],
    output:
        nii=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-preeddy_dwi.nii.gz"
        ),
        bvec=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-preeddy_dwi.bvec"
        ),
        bval=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-preeddy_dwi.bval"
        ),
        json=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-preeddy_dwi.json"
        ),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "export_main_dwi_for_eddy.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "export_main_dwi_for_eddy.tsv")
    script:
        "../scripts/export_main_dwi_for_eddy.py"


rule write_eddy_index:
    input:
        roles_json=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-dwiroles.json"
        ),
        preeddy_nii=rules.export_main_dwi_for_eddy.output.nii,
    output:
        index_txt=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-eddy_index.txt"
        ),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "write_eddy_index.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "write_eddy_index.tsv")
    script:
        "../scripts/write_eddy_index.py"


rule make_eddy_mask:
    input:
        roles_json=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-dwiroles.json"
        ),
        mif_01=rules.mrdegibbs_run_01.output.mif,
        mif_02=rules.mrdegibbs_run_02.output.mif,
    output:
        mask=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-eddy_mask.nii.gz"
        ),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "make_eddy_mask.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "make_eddy_mask.tsv")
    threads:
        DWI2MASK_NTHREADS
    script:
        "../scripts/make_eddy_mask.py"


rule run_eddy:
    input:
        preeddy_nii=rules.export_main_dwi_for_eddy.output.nii,
        preeddy_bvec=rules.export_main_dwi_for_eddy.output.bvec,
        preeddy_bval=rules.export_main_dwi_for_eddy.output.bval,
        mask=rules.make_eddy_mask.output.mask,
        acqparams=rules.write_acqparams.output.acqparams_txt,
        index_txt=rules.write_eddy_index.output.index_txt,
        topup_fieldcoef=rules.run_topup.output.fieldcoef,
        topup_movpar=rules.run_topup.output.movpar,
    output:
        nii=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-eddy_dwi.nii.gz"
        ),
        bvec=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-eddy_dwi.bvec"
        ),
        bval=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-eddy_dwi.bval"
        ),
    params:
        eddy_base=lambda wildcards: os.path.join(
            OUTDIR,
            f"sub-{wildcards.subject}",
            "dwi",
            f"sub-{wildcards.subject}_desc-eddy_dwi_work",
        ),
        topup_base=lambda wildcards: os.path.join(
            OUTDIR,
            f"sub-{wildcards.subject}",
            "dwi",
            f"sub-{wildcards.subject}_desc-topup",
        ),
        eddy_exe=EDDY_EXE,
    log:
        os.path.join(LOGDIR, "sub-{subject}", "run_eddy.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "run_eddy.tsv")
    threads:
        EDDY_NTHREADS
    container:
        config["singularity"]["fsl"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.nii}")"
        mkdir -p "$(dirname "{log}")"

        "{params.eddy_exe}" \
          --imain="{input.preeddy_nii}" \
          --mask="{input.mask}" \
          --acqp="{input.acqparams}" \
          --index="{input.index_txt}" \
          --bvecs="{input.preeddy_bvec}" \
          --bvals="{input.preeddy_bval}" \
          --topup="{params.topup_base}" \
          --out="{params.eddy_base}" \
          --nthr={threads} \
          &> "{log}"

        mv "{params.eddy_base}.nii.gz" "{output.nii}"
        mv "{params.eddy_base}.eddy_rotated_bvecs" "{output.bvec}"
        cp "{input.preeddy_bval}" "{output.bval}"
        """
