import os

os.environ['OPENBLAS_NUM_THREADS'] = '24'  # setup for Pearson matrix calculation
from scipy.stats import kendalltau
from scipy.spatial.distance import pdist
from sklearn.metrics import pairwise_distances
import pandas as pd
import numpy as np
import time
from tqdm import tqdm
from multiprocessing import Pool
from argparse import ArgumentParser
import json
from tqdm import tqdm
import scipy.io
from tqdm.contrib.concurrent import process_map

def parse_args():
    parser = ArgumentParser('Python benchmarking')
    parser.add_argument('--num_threads', default=24, type=int)
    parser.add_argument('--metric', required=True, choices=['kendall'])
    parser.add_argument('--method', required=True, choices=['pandas', 'pythonic'])
    parser.add_argument('--input', required=True, help='Path to dataset')
    parser.add_argument('--times', required=True, help='How many times to do benchmarking', type=int)
    parser.add_argument('--output', required=True, help='Path to output file')    
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    if args.input.endswith('.mtx'):
        mtx = scipy.io.mmread(args.input)

        df = pd.DataFrame.sparse.from_spmatrix(mtx.T)
    else:
        df = pd.read_csv(args.input, index_col=0)

    np_array = df.values
    print(np_array.shape)

    
    def calculate_kendall(indices):
        i, j = indices
        return (1.0 - kendalltau(np_array[i], np_array[j]).correlation) / 2.0
    
    def kendall(a, b):
        return (1.0 - kendalltau(a, b).correlation) / 2.0

    times = []
    
    functions = {
        'kendall': calculate_kendall,
    }
    
    function = functions[args.metric]
    
    for iteration_index in tqdm(range(args.times)):
        start = time.time()
        if args.method == 'pythonic':
            
            if args.metric == 'kendall':
                list_indices = [(i, j) for i in range(0, np_array.shape[0]) for j in range(i, np_array.shape[0])]


                output = np.zeros((np_array.shape[0], np_array.shape[0]), dtype=np.float32)

                output_results = process_map(function, list_indices, chunksize=10000)
                for (i, j), distance in zip(list_indices, output_results):
                    output[i, j] = distance
                    output[j, i] = distance
                
        else:
            metric = args.metric
            output = df.T.corr(method=metric)
        
        end = time.time()

        diff = (end - start) * 1000000

        times.append(diff)
    
        result = pd.DataFrame(times)
        result.to_csv(args.output, index=None)

    print(np.mean(times), np.std(times), np.max(times),times)
