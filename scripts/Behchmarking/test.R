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

    gc()
}


write.table(measurements, glue("{output}_{method}_{metric}.csv"), sep=',')
