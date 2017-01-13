library(dplyr)
b = import('base')
io = import('io')
ar = import('array')

INDEX = commandArgs(TRUE)[1] %or% "../../util/lincs/index.RData"
OUTFILE = commandArgs(TRUE)[2] %or% "speed_linear.RData"

row2scores = function(i, index, exps) {
    df = import('data_frame')
    lincs = import('data/lincs')
    spia = import('../../util/spia')

    row = index[i,]
    sign = row$sign
    ptb = df$subset(exps, row)$distil_id

    row$pathway = "control"
    row$pert_id = "DMSO"
    row$pert_dose = NULL
    row$sign = "0"
    ctl = df$subset(exps, row)$distil_id
    if (length(ctl) > 100)
        ctl = sample(ctl, 100, replace=FALSE)

    expr = lincs$get_z(c(ctl,ptb), rid=lincs$projected, map_genes="entrezgene")

    result = spia$spia(samples = expr[,ptb],
                       control = expr[,ctl],
                       pathids=spia$speed2kegg)

    if (is.numeric(result))
        setNames(result, spia$kegg2speed[names(result)])
    else
        stop(result)
}

# load model vectors and experiment index
exps = io$load(INDEX)

index = exps %>%
    select(pathway, cell_id, pert_id, pert_dose, pert_time, sign) %>%
    filter(pathway != "control") %>%
    distinct()

scores = clustermq::Q(row2scores, i=seq_len(nrow(index)),
                      const=list(index=index, exps=exps),
                      memory=10240, n_jobs=50, fail_on_error=FALSE)

scores[sapply(scores, function(r) class(r) == "try-error")] = NA
scores = ar$stack(scores, along=1) %>%
    ar$map(along=1, scale)

save(scores, index, file=OUTFILE)
