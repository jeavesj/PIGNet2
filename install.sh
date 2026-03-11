#!/usr/bin/env bash
# install.sh — reproducible environment setup for PIGNet2
#
# Tested on: Python 3.9, CUDA 12.6 (driver 560), NVIDIA H200
# Diverges from the original repo's README in a few ways — see README.md for details.
#
# Usage:
#   bash install.sh
#
# Prerequisites:
#   - conda is available
#   - NVIDIA driver >= 525 (CUDA 12.x capable)

set -euo pipefail

ENV_NAME="pignet2"

echo "==> Creating conda environment '${ENV_NAME}' (Python 3.9)..."
conda create -y -n "${ENV_NAME}" python=3.9

echo "==> Installing conda packages (rdkit, openbabel, pymol-open-source)..."
conda install -y -n "${ENV_NAME}" \
    rdkit=2022.03.4 \
    openbabel \
    pymol-open-source \
    -c conda-forge

echo "==> Installing pip dependencies..."
conda run -n "${ENV_NAME}" pip install -r requirements.txt

echo ""
echo "Done. Activate with:  conda activate ${ENV_NAME}"
