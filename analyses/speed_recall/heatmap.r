library(dplyr)
b = import('base')
io = import('io')

INFILE = commandArgs(TRUE)[1] %or% "../../scores/speed/speed_linear.RData"
OUTFILE = commandArgs(TRUE)[2] %or% "speed_linear.pdf"

scores = io$load(INFILE)
index = scores$index %>%
    mutate(id = rownames(.)) %>%
    select(id, pathway, cells, accession, effect) %>%
    arrange(pathway)

scores = scores$scores[index$id,]
scores = t(scores)
rownames(scores) = substr(rownames(scores), 0, 40)

# remove id column, add names for pheatmap to understand
rownames(index) = index$id
index$id = NULL

pdf(OUTFILE, paper="a4r", width=26, height=20)
on.exit(dev.off)

pheatmap::pheatmap(scores,
                   annotation = index,
                   scale = "column",
                   cluster_cols = FALSE,
                   show_colnames = FALSE,
                   annotation_legend = FALSE)
