# PIGNet2: A versatile deep learning-based protein-ligand interaction prediction model for accurate binding affinity scoring and virtual screening
This repository is the official implementation of [PIGNet2: A versatile deep learning-based protein-ligand interaction prediction model for accurate binding affinity scoring and virtual screening](https://arxiv.org/abs/2307.01066).

## Installation
You can download this repository by `git clone https://github.com/mseok/PIGNet2.git`. Then, you can proceed with the following steps.

## Requirements
### Environment Setup
You can use `conda` or `venv` for environment setting.
For the case of using `conda`, create the environment named `pignet2` as following.
```console
conda create -n pignet2 python=3.9
conda activate pignet2
conda install rdkit=2022.03.4 openbabel pymol-open-source -c conda-forge
```

### Install Dependencies
```console
pip install -r requirements.txt
```

### Notes on installation (CUDA 12.x systems)

> The steps above match the original upstream README. The following notes
> document changes made when installing on a system with **CUDA 12.6 / driver 560**
> (e.g. NVIDIA H200). A convenience script `install.sh` encapsulates everything.

**Three issues were found and fixed relative to the original repo:**

1. **`dimorphite_dl` was removed from PyPI** and the latest versions on GitHub
   require Python ≥ 3.10 (this repo uses Python 3.9). Additionally, the
   `DimorphiteDL` class used in `dataset/preprocess/protonate.py` does not
   exist in any published version of the package. A compatibility shim built
   on the v1.2.4 source has been committed to
   `dataset/preprocess/dimorphite_dl/`, which is already on `sys.path` via
   `src/exe/path.py`, so no extra steps are needed.

2. **`torch==1.9.1+cu111` (CUDA 11.1) is incompatible with CUDA 12.x drivers.**
   `torch-sparse` tried to load `libcusparse.so.11` which does not exist on
   CUDA 12.x systems. `requirements.txt` has been updated to
   `torch==2.4.1` via `--extra-index-url https://download.pytorch.org/whl/cu121`,
   which bundles CUDA 12.1 libraries and runs on any CUDA 12.x driver.

3. **PyTorch Geometric extension packages** (`torch-scatter`, `torch-sparse`,
   `torch-cluster`, `torch-spline-conv`) were pinned to cu111 builds and
   updated to matching cu121 builds for torch 2.4.x. `torch-geometric` was
   updated from 2.0.3 → 2.4.0 accordingly.

**Quick install (CUDA 12.x):**
```console
bash install.sh
```

## Data

Donwload our source data into `dataset` directory in this repository.
By executing `dataset/download.sh`, you can download all the following datasets.
> training dataset
- PDBbind v2020 scoring
- PDBbind v2020 docking
- PDBbind v2020 cross
- PDBbind v2020 random
> benchmark dataset
- CASF-2016 socring
- CASF-2016 docking
- CASF-2016 screening
- DUD-E screening
- derivative benchmark

Then, you can extract the downloaded files by executing `dataset/untar.sh`.

## Training
Training scripts can be found in `experiments/training_scripts` directory.
We provide 4 scripts for training.
- `baseline.sh`: training without any data augmentation
- `only_nda.sh`: training only with negative data augmentation
- `only_pda.sh`: training only with positive data augmentation
- `pda_nda.sh`: training with both positive and negative data augmentation

If you execute the script, the result files will be generated in your **current working directory**.
By default, we recommend you to execute training scripts at `experiemnts` directory.
All the result files are placed in `outputs/${EXPERIMENT_NAME}` directory.

## Benchmark
Benchmark scripts can be found in `experiments/benchmark_scripts` directory.
We provide 5 scripts for benchmark.
- `casf2016_scoring.sh`: benchmark on CASF-2016 scoring benchmark
- `casf2016_docking.sh`: benchmark on CASF-2016 docking benchmark
- `casf2016_screening.sh`: benchmark on CASF-2016 screening benchmark
- `dude.sh`: benchmark on DUD-E benchmark
- `derivative.sh`: benchmark on derivative benchmark (2015)

After training, you have to set the `${BENCHMARK_DIR}` in each benchmark scripts, which is set as `experiments/outputs/${EXPERIMENT_NAME}` as default.
Since `experiments/outputs` is set as a root directory of each experiment, it is highly recommended to place the `outputs` directory inside `experiments` directory.
For using our pre-trained model for benchmark, please refer to the [next section](#pre-trained-models).

After that, you will get the benchmark result files in `experiments/outputs/${EXPERIMENT_NAME}/benchmark`.
To benchmark each result files, you can execute `src/benchmark/*.py`.
For example, you can perform DUD-E benchmark by the following command.
```console
src/benchmark/dude_screening_power.py -f experiments/outputs/${EXPERIMENT_NAME}/benchmark/result_dude_${EPOCH}.txt -v
```

## Pre-trained Models
You can find the pre-trained models in `src/ckpt`.
We provide PIGNet2 models trained with both positive and negative data augemntation, which is the best model.
You can execute the `experiments/benchmark/pretrained_*.sh` scripts to get the benchmark results of pre-trained models.
The scripts will generate result files in `experiments/pretrained`.

# Using PIGNet2 for a single data point
> [!NOTE]  
> We highly recommend to use SMINA-optimized ligand conformations and doing 4-model ensemble to get accurate results.

Prepare protein pdb file and ligand sdf.
Execute the following command to generate the result in `$OUTPUT` path (the output path is `predict.txt` by default):
```console
python src/exe/predict.py ./src/ckpt/pda_0.pt -p $PROTEIN -l $LIGAND -o $OUTPUT
```
By default, each element of result are named as `$(basename $PROTEIN .pdb)_$(basename $LIGAND .sdf)_${idx}`, where `${idx}` is an index of ligand conformation.

## Case 1: a single pdb and a single sdf with one conformation
```console
python src/exe/predict.py ./src/ckpt/pda_0.pt -p examples/protein.pdb -l examples/ligand_single_conformation.sdf -o examples/case1.txt
```

## Case 2: a single pdb and a single sdf with multiple conformations
`src/exe/predict.py` automatically enumerates all conformations in ligand sdf.
```console
python src/exe/predict.py ./src/ckpt/pda_0.pt -p examples/protein.pdb -l examples/ligand1.sdf -o examples/case2.txt
```

## Case 3: a single pdb and multiple sdfs with multiple conformations
`src/exe/predict.py` automatically make protein-ligand pairs for a single pdb and all ligand sdfs.
```console
python src/exe/predict.py ./src/ckpt/pda_0.pt -p examples/protein.pdb -l examples/ligand1.sdf examples/ligand2.sdf -o examples/case3.txt
```

## Case 4: multiple pdbs and multiple sdfs with multiple conformations
In this case, you should match the order of ligand and protein files and all of them sequentially.
For example, if you have `protein1-ligand1`, `protein1-ligand2`, `protein2-ligand3`, you should do like following:
```console
python src/exe/predict.py ./src/ckpt/pda_0.pt -p protein1.pdb protein1.pdb protein2.pdb -l ligand1.sdf ligand2.sdf ligand3.sdf
```
