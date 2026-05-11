import os

RUN_METADATA_DIR = os.path.join(OUTDIR, "run_metadata")


rule archive_run_metadata:
    input:
        preproc_dwi=expand(
            os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-preproc_dwi.mif"),
            subject=inputs.zip_lists["dwi_run_01"]["subject"],
        ),
        brain_mask=expand(
            os.path.join(OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-brain_mask.nii.gz"),
            subject=inputs.zip_lists["dwi_run_01"]["subject"],
        ),
    output:
        metadata_dir=directory(RUN_METADATA_DIR),
    params:
        output_dir=OUTDIR,
        repo_root=workflow.basedir,
    script:
        "../scripts/utils/archive_run_metadata.py"
