#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <bids_dir> <output_dir> [snakemake flags] [config_key=value ...]"
    exit 1
fi

BIDS_DIR=$(realpath "$1")
OUTPUT_DIR=$(realpath "$2")
shift 2

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TIMESTAMP=$(date +"%Y%m%dT%H%M%S")

LOG_DIR="${OUTPUT_DIR}/logs"
METADATA_DIR="${OUTPUT_DIR}/run_metadata"

mkdir -p "${LOG_DIR}"
mkdir -p "${METADATA_DIR}"

SNAKEMAKE_ARGS=()
CONFIG_ARGS=()

for arg in "$@"; do
    if [[ "$arg" == *=* ]]; then
        CONFIG_ARGS+=("$arg")
    else
        SNAKEMAKE_ARGS+=("$arg")
    fi
done

CMD=(
    snakemake
    -p
    --cores
    all
    --profile
    none
    "${SNAKEMAKE_ARGS[@]}"
    --config
    "bids_dir=${BIDS_DIR}"
    "output_dir=${OUTPUT_DIR}"
    "${CONFIG_ARGS[@]}"
)

printf '%q ' "${CMD[@]}" > "${METADATA_DIR}/command.txt"
printf '\n' >> "${METADATA_DIR}/command.txt"

snakemake --version > "${METADATA_DIR}/snakemake_version.txt" 2>/dev/null || echo "unknown" > "${METADATA_DIR}/snakemake_version.txt"
python3 --version > "${METADATA_DIR}/python_version.txt" 2>/dev/null || true

if git -C "${REPO_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "${REPO_ROOT}" rev-parse HEAD > "${METADATA_DIR}/git_commit.txt" 2>/dev/null || echo "unknown" > "${METADATA_DIR}/git_commit.txt"
    git -C "${REPO_ROOT}" status --short > "${METADATA_DIR}/git_status.txt" 2>/dev/null || true
else
    echo "not_a_git_repo" > "${METADATA_DIR}/git_commit.txt"
    : > "${METADATA_DIR}/git_status.txt"
fi

"${CMD[@]}" 2>&1 | tee "${LOG_DIR}/snakemake_main_${TIMESTAMP}.log"
