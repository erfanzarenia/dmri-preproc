import os


MIN_DENOISE_VOLUMES = config["mrtrix"].get("min_denoise_volumes", 30)
DENOISE_ENABLED = config["mrtrix"].get("denoise", True)
DEGIBBS_ENABLED = config["mrtrix"].get("degibbs", True)

rule dwidenoise_run_01:
    input:
        mif=rules.convert_to_mif_run_01.output.mif,
    output:
        mif=temp(
            bids(
                root=OUTDIR,
                datatype="dwi",
                suffix="dwi.mif",
                desc="denoise",
                run="01",
                subject="{subject}",
            )
        )
    log:
        os.path.join(LOGDIR, "sub-{subject}", "dwidenoise_run_01.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "dwidenoise_run_01.tsv")
    params:
        min_volumes=MIN_DENOISE_VOLUMES,
        denoise_enabled=str(DENOISE_ENABLED).lower(),
    threads:
        config["threads"]["mrtrix"].get("dwidenoise", config["threads"].get("default", 1))
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.mif}")"
        mkdir -p "$(dirname "{log}")"

        if [ "{params.denoise_enabled}" != "true" ]; then
            echo "Skipping dwidenoise: disabled in config." > "{log}"
            cp "{input.mif}" "{output.mif}"

        else
            ndims=$(mrinfo -ndim "{input.mif}")

            if [ "$ndims" -lt 4 ]; then
                echo "Skipping dwidenoise: ndim=$ndims (not 4D)" > "{log}"
                cp "{input.mif}" "{output.mif}"

            else
                nvols=$(mrinfo -size "{input.mif}" | awk '{{print $4}}')

                if [ "$nvols" -lt "{params.min_volumes}" ]; then
                    echo "Skipping dwidenoise: nvols=$nvols < {params.min_volumes}" > "{log}"
                    cp "{input.mif}" "{output.mif}"
                else
                    dwidenoise -nthreads {threads} "{input.mif}" "{output.mif}" > "{log}" 2>&1
                fi
            fi
        fi
        """


rule dwidenoise_run_02:
    input:
        mif=rules.convert_to_mif_run_02.output.mif,
    output:
        mif=temp(
            bids(
                root=OUTDIR,
                datatype="dwi",
                suffix="dwi.mif",
                desc="denoise",
                run="02",
                subject="{subject}",
            )
        )
    log:
        os.path.join(LOGDIR, "sub-{subject}", "dwidenoise_run_02.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "dwidenoise_run_02.tsv")
    params:
        min_volumes=MIN_DENOISE_VOLUMES,
        denoise_enabled=str(DENOISE_ENABLED).lower(),
    threads:
        config["threads"]["mrtrix"].get("dwidenoise", config["threads"].get("default", 1))
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.mif}")"
        mkdir -p "$(dirname "{log}")"

        if [ "{params.denoise_enabled}" != "true" ]; then
            echo "Skipping dwidenoise: disabled in config." > "{log}"
            cp "{input.mif}" "{output.mif}"

        else
            ndims=$(mrinfo -ndim "{input.mif}")

            if [ "$ndims" -lt 4 ]; then
                echo "Skipping dwidenoise: ndim=$ndims (not 4D)" > "{log}"
                cp "{input.mif}" "{output.mif}"

            else
                nvols=$(mrinfo -size "{input.mif}" | awk '{{print $4}}')

                if [ "$nvols" -lt "{params.min_volumes}" ]; then
                    echo "Skipping dwidenoise: nvols=$nvols < {params.min_volumes}" > "{log}"
                    cp "{input.mif}" "{output.mif}"
                else
                    dwidenoise -nthreads {threads} "{input.mif}" "{output.mif}" > "{log}" 2>&1
                fi
            fi
        fi
        """


rule mrdegibbs_run_01:
    input:
        mif=rules.dwidenoise_run_01.output.mif,
    output:
        mif=bids(
            root=OUTDIR,
            datatype="dwi",
            suffix="dwi.mif",
            desc="degibbs",
            run="01",
            subject="{subject}",
        )
    log:
        os.path.join(LOGDIR, "sub-{subject}", "mrdegibbs_run_01.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "mrdegibbs_run_01.tsv")
    params:
        degibbs_enabled=str(DEGIBBS_ENABLED).lower(),
    threads:
        config["threads"]["mrtrix"].get("mrdegibbs", config["threads"].get("default", 1))
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.mif}")"
        mkdir -p "$(dirname "{log}")"

        if [ "{params.degibbs_enabled}" != "true" ]; then
            echo "Skipping mrdegibbs: disabled in config." > "{log}"
            cp "{input.mif}" "{output.mif}"
        else
            mrdegibbs -nthreads {threads} "{input.mif}" "{output.mif}" > "{log}" 2>&1
        fi
        """


rule mrdegibbs_run_02:
    input:
        mif=rules.dwidenoise_run_02.output.mif,
    output:
        mif=bids(
            root=OUTDIR,
            datatype="dwi",
            suffix="dwi.mif",
            desc="degibbs",
            run="02",
            subject="{subject}",
        )
    log:
        os.path.join(LOGDIR, "sub-{subject}", "mrdegibbs_run_02.log")
    benchmark:
        os.path.join(BENCHDIR, "sub-{subject}", "mrdegibbs_run_02.tsv")
    params:
        degibbs_enabled=str(DEGIBBS_ENABLED).lower(),
    threads:
        config["threads"]["mrtrix"].get("mrdegibbs", config["threads"].get("default", 1))
    container:
        config["singularity"]["mrtrix"]
    shell:
        r"""
        mkdir -p "$(dirname "{output.mif}")"
        mkdir -p "$(dirname "{log}")"

        if [ "{params.degibbs_enabled}" != "true" ]; then
            echo "Skipping mrdegibbs: disabled in config." > "{log}"
            cp "{input.mif}" "{output.mif}"
        else
            mrdegibbs -nthreads {threads} "{input.mif}" "{output.mif}" > "{log}" 2>&1
        fi
        """
