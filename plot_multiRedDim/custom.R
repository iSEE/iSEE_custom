
stopifnot(suppressPackageStartupMessages({
    require(cowplot)
}))

#' Highlight selected samples in all dimensionality reduction results
#'
#' Detect all dimensionality reduction results,
#' present their first two dimensions,
#' and highlight a selection of samples in all plots.
#'
#' @param se A \code{SummarizedExperiment} object.
#' @param rows Selected rows (i.e., features).
#' @param columns Selected columns (i.e., samples).
#'
#' @return A \code{ggplot}
#'
#' @author Kevin Rue-Albrecht
#'
CUSTOM_MULTI <- function(se, rows, columns) {
    ggList <- list()
    for (rdName in reducedDimNames(sce)) {
        rdData <- data.frame(
            X=reducedDim(sce, rdName)[, 1],
            Y=reducedDim(sce, rdName)[, 2],
            Selected=FALSE)
        if (!is.null(columns)) {
            rdData[columns, "Selected"] <- TRUE
        }
        gg <- ggplot(rdData, aes(X, Y)) +
            labs(title=rdName, x="Dimension 1", y="Dimension 2")
        if (sum(rdData$Selected) > 0) {
            gg <- gg + geom_point(aes(color=Selected))
        } else {
            gg <- gg + geom_point()
        }
        ggList[[rdName]] <- gg
    }
    plot_grid(plotlist = ggList, nrow = 1)
}
