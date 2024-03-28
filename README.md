# Article-GADES

This repository represents generating and benchmarking the results of the [GADES](https://github.com/lab-medvedeva/GADES-main) package for Distance Matrix Calculation

## Installation

```shell
git lfs install
git clone https://github.com/lab-medvedeva/Article-GADES.git
cd Article-GADES
```

Put the Real datasets in the MEX format to the folder `Datasets/Real`.

### Running benchmark using Docker Deployment
```shell
docker run --gpus all \
    -v $PWD/Datasets:/workspace/Article-GADES/Datasets \
    -v $PWD/results:/workspace/Article-GADES/results \
    akhtyamovpavel/article-gades 
```

## Step 01. Generation of the datasets

### Step 01.1. Generated Dense Datasets

```shell
cd ./scripts/MatricesGeneration
./generate_dense.sh ../../Datasets/
```

### Step 01.2. Generated Sparse Datasets

```shell
cd ./scripts/MatricesGeneration
./generate_sparse.sh ../../Datasets/
```

## Step 02. Behchmarking

### Step 02.1. Generated Dense Datasets
```shell
cd ./scripts/Behchmarking

./run_benchmark_generated_dense.sh ../../
```

### Step 02.2. Generated Sparse Datasets

```shell

cd ./scripts/Behchmarking/

./run_benchmark_generated_sparse.sh ../../
```

### Step 02.3 Real Datasets
```shell

cd ./Scripts/Benchmarking/
./run_benchmark_real_python.sh <path to dataset> ../../results/RealDatasets/<name of the real dataset>/
```

Example:
```shell
./run_benchmark.sh ../../Datasets/Real/HLCA_marrow.mtx ../results/RealDatasets/HLCA_marrow/
```


## Step 03. Drawing charts


