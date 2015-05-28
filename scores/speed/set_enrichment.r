b = import('base')
io = import('io')
gdsc = import('data/gdsc')
gsea = import('../../genesets/gsea')

INFILE = commandArgs(TRUE)[1] %or% "../../genesets/go.RData"
OUTFILE = commandArgs(TRUE)[2] %or% "go.RData"

# load gene list and expression
genelist = io$load(INFILE)
speed = io$load('../../data/dscores.RData')
expr = speed$scores

## use only experiments with > 18000 genes so we can compare GSEA scores
#expr = na.omit(expr[,colSums(!is.na(expr)) > 18000])

# perform GSEA
result = gsea$runGSEA(expr, genelist, transform.normal=TRUE)

save(result, file=OUTFILE)
