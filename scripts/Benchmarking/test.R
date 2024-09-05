library(amap)
library(GADES)
library(Matrix)
library(factoextra)
library(glue)

args = commandArgs(trailingOnly=TRUE)
datain = args[1]
method = args[2]
times = strtoi(args[3])
metric = args[4]
batch_size = strtoi(args[5])
output = args[6]
sparse = as.logical(args[7])
filename = args[8]
profile = as.logical(args[9])

if (profile) {
    library(profmem)
}
print(glue('Reading table. Output folder will be {output}_{method}_{metric}.csv'))

if (sparse) {
    data <- readMM(datain)
} else {
    data <- t(as.matrix(read.table(datain, header=T, row.names = 1, sep=",")))
}
print('Completed reading')

measurements <- numeric(times)

for (i in 1:times) {
    st_t <- as.numeric(Sys.time()) * 1000000

    if (method == 'GPU') {
        distMatrix_mtrx <- mtrx_distance(data, batch_size = batch_size , metric = metric,type="gpu",sparse=sparse, filename=filename)
        print(dim(distMatrix_mtrx))
    } else if (method == 'CPU') {
        print(metric)
        distMatrix_mtrx <- mtrx_distance(data, batch_size = batch_size, metric = metric, type="cpu", sparse=sparse, filename=filename)
        print(dim(distMatrix_mtrx))
    } else if (method == 'amap') {
        print('Calc dist')
        distMatrix_mtrx <- as.matrix(Dist(t(data), method=metric, nbproc=24))
    } else if (method == 'factoextra') {
        if (!sparse) {
            data <- as.matrix(data)
        }

        distMatrix_mtrx <- as.matrix(get_dist(t(data), method = metric))
        print('Factoextra')
    }
    end_time <- as.numeric(Sys.time()) * 1000000
    measurements[i] <- end_time - st_t
    write.table(measurements, glue("{output}_{method}_{metric}.csv"), sep=',')

    if (profile) {
        p <- profmem_end()
        if (method == 'amap' || method == 'factoextra') {
            delta <- object.size(distMatrix_mtrx)
        } else {
            delta <- 0
        }
        print(p)
        sum_bytes <- sum(p$bytes, na.rm=T)
        end <- as.numeric(ps::ps_memory_info()['rss'][1])
        print('Memory usage')
        print(c(sum_bytes, delta))

        delta_manual <- 0
        print(method)
        if (method == 'CPU' || method == 'GPU') {
            batch_size_effective <- min(dim(data)[2], batch_size)
            features <- dim(data)[1]
            print(glue('Number of cells: {dim(data)[2]}'))
            print(glue('Batch size effective: {batch_size_effective}'))
            if (!sparse) {
                delta_manual <- (batch_size_effective * batch_size_effective + 2 * batch_size_effective * features) * 4
            } else {
                delta_manual <- (batch_size_effective * batch_size_effective + 2 * length(data@x) ) * 4
            }
            print(glue('Manual delta: {delta_manual}'))
        }
        memories[i, 1] <- sum_bytes + delta_manual
        memories[i, 2] <- delta
        memories[i, 3] <- delta_manual
        memories[i, 4] <- end - start
        write.table(memories, glue("{output}_{method}_{metric}_memory.csv", sep=','))
    }
    
    gc()
}


write.table(measurements, glue("{output}_{method}_{metric}.csv"), sep=',')
