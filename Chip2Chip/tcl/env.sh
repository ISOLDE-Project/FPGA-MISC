#!/usr/bin/env bash
# Copyleft

# Define environment variables
MINICONDA=~/miniconda3/etc/profile.d/conda.sh
MINICONDA_ENV=my_env
# To activate this environment, use
#
#     $ conda activate my_env
#
# To deactivate an active environment, use
#
#     $ conda deactivate

# Get the root directory of the Git repository
export ROOT_DIR=$(git rev-parse --show-toplevel)


source $MINICONDA
conda activate $MINICONDA_ENV