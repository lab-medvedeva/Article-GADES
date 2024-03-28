#!/bin/bash


dataset=$1
experiment_name=$2

output_folder=${experiment_name}
for method in "CPU" "GPU" "amap" "factoextra"
do
    for metric in "kendall"
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
            times=10
            echo Rscript test.R $dataset $method $times $metric 5000 $output_folder/$density $dense
            if [[ $density == "dense" && $method == "CPU" ]]
            then
                continue
            fi


            Rscript test.R $dataset $method $times $metric 5000 $output_folder/$density $dense $output_folder/${density}_matrix
        done
    done
done

wait
