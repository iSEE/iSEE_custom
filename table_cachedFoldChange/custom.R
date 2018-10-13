
#' Table of log fold-change between a set of samples and all other samples.
#'
#' Compute the fold-change between the selected samples and all other samples for all features,
#' while displaying only results for the selected features.
#'
#' @param se A \code{SummarizedExperiment} object.
#' @param rows Selected rows (i.e., features).
#' @param columns Selected columns (i.e., samples).
#'
#' @return A \code{data.frame}.
#'
#' @author Aaron Lun, Kevin Rue-Albrecht
#'
CUSTOM_LFC <- function(se, rows, columns) {
    if (is.null(columns)) {
        return(data.frame(logFC=numeric(0)))
    }

    if (!identical(caching$columns, columns)) {
        caching$columns <- columns
        in.subset <- rowMeans(logcounts(sce)[, columns])
        out.subset <- rowMeans(logcounts(sce)[, setdiff(colnames(sce), columns)])
        caching$logFC <- setNames(in.subset - out.subset, rownames(sce))
    }

    lfc <- caching$logFC
    if (!is.null(rows)) {
        out <- data.frame(logFC=lfc[rows], row.names=rows)
    } else {
        out <- data.frame(logFC=lfc, row.names=rownames(se))
    }
    out <- out[order(out$logFC, decreasing=TRUE), , drop=FALSE]
    out
}

# Set up a cache for selected columns (i.e., samples) and log fold-change values.
# The function uses this cache to avoid recomputing the log fold-change values if only the row selection changes (i.e., features),
# as in that case the function only needs to change which results are displayed.
caching <- new.env()
