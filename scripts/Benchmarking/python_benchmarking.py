import os

import sys
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
import gc
from tqdm.contrib.concurrent import process_map
import psutil

def parse_args():
    parser = ArgumentParser('Python benchmarking')
    parser.add_argument('--num_threads', default=24, type=int)
    parser.add_argument('--metric', required=True, choices=['kendall'])
    parser.add_argument('--method', required=True, choices=['pandas', 'pythonic'])
    parser.add_argument('--input', required=True, help='Path to dataset')
    parser.add_argument('--times', required=True, help='How many times to do benchmarking', type=int)
    parser.add_argument('--output', required=True, help='Path to output file')
    parser.add_argument('--profile', action='store_true', help='Whether to run memory profiler')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    process = psutil.Process(os.getpid())
#    if args.profile:
#        gc.disable()
    if args.input.endswith('.mtx'):
        mtx = scipy.io.mmread(args.input)
        if args.profile:
            base_memory_usage = process.memory_info().rss
        df = pd.DataFrame.sparse.from_spmatrix(mtx.T)
    else:
        df = pd.read_csv(args.input, index_col=0)
        if args.profile:
            base_memory_usage = process.memory_info().rss

    np_array = df.values
    print(np_array.shape)

    
    def calculate_kendall(indices):
        i, j = indices
        return (1.0 - kendalltau(np_array[i], np_array[j]).correlation) / 2.0
    
    def kendall(a, b):
        return (1.0 - kendalltau(a, b).correlation) / 2.0

    if args.profile:
        memories = []
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

                output_results = process_map(function, list_indices, chunksize=10000, max_workers=args.num_threads)
                for (i, j), distance in zip(list_indices, output_results):
                    output[i, j] = distance
                    output[j, i] = distance
                
        else:
            metric = args.metric
            output = df.T.corr(method=metric)

        if args.profile:
            result_memory_usage = process.memory_info().rss
            output_usage = sys.getsizeof(output)

            memory_usage = result_memory_usage - base_memory_usage - output_usage

            memories.append({
                'base': base_memory_usage,
                'result': result_memory_usage,
                'output': output_usage,
                'found': memory_usage,
            })
        end = time.time()

        diff = (end - start) * 1000000

        times.append(diff)
    
        result = pd.DataFrame(times)
        result.to_csv(args.output, index=None)
        if args.profile:
            result_memories = pd.DataFrame(memories)
            result_memories.to_csv(args.output.replace('.csv', '_memory.csv'), index=None)

    print(np.mean(times), np.std(times), np.max(times),times)
