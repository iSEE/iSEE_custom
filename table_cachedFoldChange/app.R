
stopifnot(suppressPackageStartupMessages({
    require(iSEE)
    require(scRNAseq)
    require(scater)
    require(shiny)
}))

data(allen)

# Example data ----

sce <- as(allen, "SingleCellExperiment")
counts(sce) <- assay(sce, "tophat_counts")
sce <- normalize(sce)

set.seed(1234)
sce <- runPCA(sce, ncomponents=4)
sce <- runTSNE(sce)

rowData(sce)$mean_log <- rowMeans(logcounts(sce))
rowData(sce)$var_log <- apply(logcounts(sce), 1, var)

# Import custom panel ----

source("custom.R")

# Import tour steps ----

tour <- read.delim("tour.txt", sep=";", quote="")

# Configure the app ----

redDimArgs <- redDimPlotDefaults(sce, 1)
redDimArgs$Type <- 2L
redDimArgs$ColorBy <- "Column data"
redDimArgs$ColorByColData <- "driver_1_s"

rowDataArgs <- rowDataPlotDefaults(sce, 1)
rowDataArgs$XAxis <- "Row data"
rowDataArgs$XAxisRowData <- "mean_log"
rowDataArgs$YAxis <- "var_log"

customStatArgs <- customStatTableDefaults(sce, 1)
customStatArgs$Function <- "CUSTOM_LFC"
customStatArgs$ColumnSource <- "Reduced dimension plot 1"
customStatArgs$RowSource <- "Row data plot 1"

initialPanels <- DataFrame(
    Name=c("Reduced dimension plot 1", "Row data plot 1", "Custom statistics table 1"),
    Width=c(4L, 4L, 4L))

app <- iSEE(
    se = sce,
    redDimArgs=redDimArgs, rowDataArgs=rowDataArgs, customStatArgs=customStatArgs,
    initialPanels=initialPanels,
    customStatFun=list(CUSTOM_LFC=CUSTOM_LFC), tour=tour, appTitle = "Custom table panel: Log fold-change (cached)")

# launch the app itself ----

runApp(app)
