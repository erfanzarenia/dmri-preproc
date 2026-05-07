import os


rule convert_to_mif_run_01:
    input:
        nii=rules.import_dwi_run_01.output[0],
        bvec=rules.import_dwi_run_01.output[1],
        bval=rules.import_dwi_run_01.output[2],
    output:
        mif=temp(
            bids(
                root=OUTDIR,
                datatype="dwi",
                suffix="dwi.mif",
                desc="import",
                run="01",
                subject="{subject}",
            )
        )
    log:
        os.path.join(LOGDIR, "sub-{subject}", "convert_to_mif_run_01.log")
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.mif}")"
        mkdir -p "$(dirname "{log}")"
        mrconvert "{input.nii}" "{output.mif}" -fslgrad "{input.bvec}" "{input.bval}" > "{log}" 2>&1
        """


rule convert_to_mif_run_02:
    input:
        nii=rules.import_dwi_run_02.output[0],
        bvec=rules.import_dwi_run_02.output[1],
        bval=rules.import_dwi_run_02.output[2],
    output:
        mif=temp(
            bids(
                root=OUTDIR,
                datatype="dwi",
                suffix="dwi.mif",
                desc="import",
                run="02",
                subject="{subject}",
            )
        )
    log:
        os.path.join(LOGDIR, "sub-{subject}", "convert_to_mif_run_02.log")
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.mif}")"
        mkdir -p "$(dirname "{log}")"
        mrconvert "{input.nii}" "{output.mif}" -fslgrad "{input.bvec}" "{input.bval}" > "{log}" 2>&1
        """
