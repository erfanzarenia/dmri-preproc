import os

TOPUP_CONFIG = config["fsl"].get("topup_config", "b02b0.cnf")
EDDY_EXE = config["software"]["fsl"].get("eddy_exe", "eddy_cpu")
SYNTHSTRIP_EXE = config["software"]["synthstrip"].get(
    "exe", "python3 /freesurfer/mri_synthstrip"
)


rule export_topup_b0pair_nii:
    input:
        mif=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_b0pair.mif"),
    output:
        nii=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_b0pair.nii.gz"),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "export_topup_b0pair_nii.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "export_topup_b0pair_nii.tsv")
    threads:
        config["threads"]["mrtrix"].get("mrconvert", config["threads"].get("default", 1))
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.nii}")" "$(dirname "{log}")"

        mrconvert -nthreads {threads} \
          "{input.mif}" "{output.nii}" \
          > "{log}" 2>&1
        """


rule run_topup:
    input:
        b0pair_nii=rules.export_topup_b0pair_nii.output.nii,
        acqparams=rules.write_acqparams.output.acqparams_txt,
    output:
        corrected_b0pair=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_b0pair_corrected.nii.gz"),
        fieldmap=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_fieldmap.nii.gz"),
        fieldcoef=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_fieldcoef.nii.gz"),
        movpar=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_movpar.txt"),
    params:
        topup_base=lambda wc: os.path.join(
            OUTDIR, f"sub-{wc.subject}", "dwi", f"sub-{wc.subject}_desc-topup"
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
        mkdir -p "$(dirname "{output.corrected_b0pair}")" "$(dirname "{log}")"

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
        roles_json=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-dwiroles.json"),
        mif_01=rules.mrdegibbs_run_01.output.mif,
        mif_02=rules.mrdegibbs_run_02.output.mif,
        json_01=rules.import_dwi_run_01.output[3],
        json_02=rules.import_dwi_run_02.output[3],
    output:
        nii=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-preeddy_dwi.nii.gz"),
        bvec=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-preeddy_dwi.bvec"),
        bval=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-preeddy_dwi.bval"),
        json=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-preeddy_dwi.json"),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "export_main_dwi_for_eddy.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "export_main_dwi_for_eddy.tsv")
    script:
        "../scripts/export_main_dwi_for_eddy.py"


rule make_preeddy_mean_b0:
    input:
        nii=rules.export_main_dwi_for_eddy.output.nii,
        bvec=rules.export_main_dwi_for_eddy.output.bvec,
        bval=rules.export_main_dwi_for_eddy.output.bval,
    output:
        b0=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-preeddy_meanb0.nii.gz"),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "make_preeddy_mean_b0.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "make_preeddy_mean_b0.tsv")
    threads:
        config["threads"]["mrtrix"].get("mrconvert", config["threads"].get("default", 1))
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.b0}")" "$(dirname "{log}")"

        mrconvert -nthreads {threads} \
          "{input.nii}" - \
          -fslgrad "{input.bvec}" "{input.bval}" \
          | dwiextract -bzero - - \
          | mrmath - mean "{output.b0}" -axis 3 \
          > "{log}" 2>&1
        """


rule make_eddy_mask:
    input:
        b0=rules.make_preeddy_mean_b0.output.b0,
    output:
        mask=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-eddy_mask.nii.gz"),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "make_eddy_mask.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "make_eddy_mask.tsv")
    threads:
        config["threads"]["synthstrip"].get("synthstrip", config["threads"].get("default", 1))
    container:
        config["singularity"]["synthstrip"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.mask}")" "$(dirname "{log}")"

        {SYNTHSTRIP_EXE} \
          -i "{input.b0}" \
          -m "{output.mask}" \
          > "{log}" 2>&1
        """


rule write_eddy_index:
    input:
        roles_json=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-dwiroles.json"),
        preeddy_nii=rules.export_main_dwi_for_eddy.output.nii,
    output:
        index_txt=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-eddy_index.txt"),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "write_eddy_index.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "write_eddy_index.tsv")
    script:
        "../scripts/write_eddy_index.py"


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
        nii=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-eddy_dwi.nii.gz"),
        bvec=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-eddy_dwi.bvec"),
        bval=os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-eddy_dwi.bval"),
    params:
        eddy_base=lambda wc: os.path.join(
            OUTDIR, f"sub-{wc.subject}", "dwi", f"sub-{wc.subject}_desc-eddy_dwi_work"
        ),
        topup_base=lambda wc: os.path.join(
            OUTDIR, f"sub-{wc.subject}", "dwi", f"sub-{wc.subject}_desc-topup"
        ),
        eddy_exe=EDDY_EXE,
    log:
        os.path.join(LOGDIR, "sub-{subject}", "run_eddy.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "run_eddy.tsv")
    threads:
        config["threads"]["fsl"].get("eddy", config["threads"].get("default", 1))
    container:
        config["singularity"]["fsl"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.nii}")" "$(dirname "{log}")"

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
