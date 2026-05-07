import os


rule import_dwi_run_01:
    input:
        nii=inputs.path["dwi_run_01"],
        bvec=inputs.path["dwi_run_01_bvec"],
        bval=inputs.path["dwi_run_01_bval"],
        json=inputs.path["dwi_run_01_json"],
    output:
        multiext(
            bids(
                root=OUTDIR,
                datatype="dwi",
                suffix="dwi",
                desc="import",
                run="01",
                **inputs.wildcards["dwi_run_01"],
            ),
            ".nii.gz",
            ".bvec",
            ".bval",
            ".json",
        )
    log:
        os.path.join(LOGDIR, "sub-{subject}", "import_dwi_run_01.log")
    shell:
        """
        mkdir -p $(dirname {output[0]})
        mkdir -p $(dirname {log})
        cp {input.nii} {output[0]}
        cp {input.bvec} {output[1]}
        cp {input.bval} {output[2]}
        cp {input.json} {output[3]} > {log} 2>&1
        """


rule import_dwi_run_02:
    input:
        nii=inputs.path["dwi_run_02"],
        bvec=inputs.path["dwi_run_02_bvec"],
        bval=inputs.path["dwi_run_02_bval"],
        json=inputs.path["dwi_run_02_json"],
    output:
        multiext(
            bids(
                root=OUTDIR,
                datatype="dwi",
                suffix="dwi",
                desc="import",
                run="02",
                **inputs.wildcards["dwi_run_02"],
            ),
            ".nii.gz",
            ".bvec",
            ".bval",
            ".json",
        )
    log:
        os.path.join(LOGDIR, "sub-{subject}", "import_dwi_run_02.log")
    shell:
        """
        mkdir -p $(dirname {output[0]})
        mkdir -p $(dirname {log})
        cp {input.nii} {output[0]}
        cp {input.bvec} {output[1]}
        cp {input.bval} {output[2]}
        cp {input.json} {output[3]} > {log} 2>&1
        """
