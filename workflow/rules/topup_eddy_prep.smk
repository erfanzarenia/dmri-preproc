import os


rule select_dwi_roles:
    input:
        json_01=rules.import_dwi_run_01.output[3],
        json_02=rules.import_dwi_run_02.output[3],
    output:
        roles_json=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-dwiroles.json"
        ),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "select_dwi_roles.log")
    script:
        "../scripts/select_dwi_roles.py"


rule extract_b0_run_01:
    input:
        mif=rules.mrdegibbs_run_01.output.mif,
    output:
        b0=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_run-01_desc-b0.mif"
        ),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "extract_b0_run_01.log")
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.b0}")"
        mkdir -p "$(dirname "{log}")"

        ndims=$(mrinfo -ndim "{input.mif}")

        if [ "$ndims" -lt 4 ]; then
            mrconvert "{input.mif}" "{output.b0}" > "{log}" 2>&1
        else
            dwiextract -bzero "{input.mif}" - | mrmath - mean "{output.b0}" -axis 3 > "{log}" 2>&1
        fi
        """


rule extract_b0_run_02:
    input:
        mif=rules.mrdegibbs_run_02.output.mif,
    output:
        b0=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_run-02_desc-b0.mif"
        ),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "extract_b0_run_02.log")
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.b0}")"
        mkdir -p "$(dirname "{log}")"

        ndims=$(mrinfo -ndim "{input.mif}")

        if [ "$ndims" -lt 4 ]; then
            mrconvert "{input.mif}" "{output.b0}" > "{log}" 2>&1
        else
            dwiextract -bzero "{input.mif}" - | mrmath - mean "{output.b0}" -axis 3 > "{log}" 2>&1
        fi
        """


rule concat_topup_b0s:
    input:
        b0_01=rules.extract_b0_run_01.output.b0,
        b0_02=rules.extract_b0_run_02.output.b0,
    output:
        b0pair=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_b0pair.mif"
        ),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "concat_topup_b0s.log")
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.b0pair}")"
        mkdir -p "$(dirname "{log}")"
        mrcat "{input.b0_01}" "{input.b0_02}" "{output.b0pair}" -axis 3 > "{log}" 2>&1
        """


rule write_acqparams:
    input:
        json_01=rules.import_dwi_run_01.output[3],
        json_02=rules.import_dwi_run_02.output[3],
    output:
        acqparams_txt=os.path.join(
            OUTDIR, "sub-{subject}", "dwi", "sub-{subject}_desc-topup_acqparams.txt"
        ),
    log:
        os.path.join(LOGDIR, "sub-{subject}", "write_acqparams.log")
    script:
        "../scripts/write_acqparams.py"
