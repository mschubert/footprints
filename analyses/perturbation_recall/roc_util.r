library(cowplot)
library(dplyr)
library(reshape2)
b = import('base')
io = import('io')
ar = import('array')
df = import('data_frame')
st = import('stats')
config = import('../../config')

#' Creates a data.frame for a scores object
#'
#' @param sobj    A file name or scores object
#' @param signed  Whether to account for inhibition as negative activation
scores2df = function(sobj, signed=TRUE) {
    if (is.character(sobj))
        sobj = io$load(sobj)

    if (signed) {
        sign = ifelse(sobj$index$effect == "activating", 1, -1)
        scores = sobj$scores * sign
    } else
        scores = sobj$scores

#    scores = ar$map(scores, along=2, function(x) scale(x,center=FALSE))
    scores = ar$map(scores, along=2, scale)

    df = data.frame(perturbed = sobj$index$pathway,
                    scores,
                    check.names = FALSE) %>%
        tidyr::gather(signature, score, -perturbed)
}

#' Returns the analysis set and their relative paths
#'
#' @param fids    Character vector of method IDs to use
#'                default: analysis set in config
#' @param return  A combined data frame of methods and recall
analysis_set = function(fids=NULL) {
    if (is.null(fids))
        fids = setdiff(config$methods$analysis_set, "paradigm")

    # data.frame with columns:
    #   perturbed : which pathway was perturbed in the experiment
    #   signature : which signature was used to quantify
    #   score     : the score assigned by the signature
    #   method    : which method the signature comes from
    scoredf = paste0(fids, ".RData") %>%
        module_file("../../scores/speed", ., mustWork = TRUE) %>%
        setNames(fids) %>%
        lapply(scores2df) %>%
        df$bind_rows(name_col="method") %>%
        mutate(inferred = signature)
}

#' Create a ROC curve plot from a roc object
roc2plot = function(roc, width=1) {
    random_line = data.frame(x=c(0,1), y=c(0,1), method=roc$method[1])

    ggplot(roc, aes(x=FPR, y=TPR, color=method)) +
        geom_line(aes(x=x, y=y), data=random_line, color="grey", linetype="dashed", size=width) +
        geom_step(size=width) +
        coord_fixed() +
        facet_wrap(~inferred) +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

#' Calculate AUCs from a roc object
roc2auc = function(roc) {
    auc = roc %>%
        mutate(method = config$id2short(method)) %>%
        group_by(method, inferred) %>%
        arrange(score) %>%
        summarize(auc = st$roc_auc(score, matched==1)) %>%
        tidyr::spread(method, auc)
}
