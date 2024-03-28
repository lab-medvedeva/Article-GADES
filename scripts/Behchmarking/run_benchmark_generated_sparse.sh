#!/bin/bash

method=$1
ROOT_FOLDER=$2

for cells in "10" "100" "1000" "10000"
do
	for features in "10" "100" "1000" "10000" "100000"
	do
		num_elements=$(( cells * features ))

		if [[ $num_elements > 10000000  || $num_elements < 10000000 ]]
		then
			continue
		fi
		
		echo $cells, $features
        for sparsity in 0.5 0.75 0.9 0.95 0.99
        do
            input=GeneratedSparse/${cells}_cells_${features}_features/$sparsity.mtx
            for metric in "kendall"
            do
                times=25

                folder=${ROOT_FOLDER}/results/GeneratedSparse/${cells}_cells_${features}_features/$sparsity
                mkdir -p $folder
                echo test.R $input $method $times $metric 5000 $folder TRUE >> commands_sparse_$method.txt
            done
        done
	done	
done
