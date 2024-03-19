#!/bin/bash


dataset=$1
experiment_name=$2

output_folder=${experiment_name}
for method in "amap" "factoextra" "CPU"
do
    for metric in "pearson" "euclidean"
    do
        for density in "dense"
        do
            if [[ $density == dense ]]
            then
                dense=FALSE
            else
                dense=TRUE
            fi
            mkdir -p $output_folder
            echo Rscript test.R $dataset $method 5 $metric 5000 $output_folder/$density $dense
            #if [[ $density == "dense" && $method == "CPU" ]]
            #then
            #    continue
            #fi


            Rscript test.R $dataset $method 1 $metric 5000 $output_folder/$density $dense $output_folder/${density}_matrix
        done
    done
done

wait
