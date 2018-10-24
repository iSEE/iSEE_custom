
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
set.seed(1234)
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
redDimArgs$BrushData <- list(
    list(xmin = -9, xmax = -4.9, ymin = 4.9, ymax = 9.7,
         mapping = list(x = "X", y = "Y", colour = "ColorBy"),
         domain = list(left = -9.57059099270312,  right = 7.86028887909233, bottom = -10.2295770832622, top = 10.1418027417992),
         range = list(left = 38.7190443065069, right = 571.520547945205, bottom = 426.852678724315, top = 23.7921069615253),
         log = list(x = NULL, y = NULL), direction = "xy",
         brushId = "redDimPlot1_Brush", outputId = "redDimPlot1"))

rowDataArgs <- rowDataPlotDefaults(sce, 1)
rowDataArgs$XAxis <- "Row data"
rowDataArgs$XAxisRowData <- "mean_log"
rowDataArgs$YAxis <- "var_log"

customDataArgs <- customDataPlotDefaults(sce, 1)
customDataArgs$Function <- "CUSTOM_MULTI"
customDataArgs$ColumnSource <- "Reduced dimension plot 1"
customDataArgs$RowSource <- "Row data plot 1"
customDataArgs$DataBoxOpen <- TRUE

initialPanels <- DataFrame(
    Name=c("Reduced dimension plot 1", "Row data plot 1", "Custom data plot 1"),
    Width=c(6L, 6L, 12L))

app <- iSEE(
    se = sce,
    redDimArgs=redDimArgs, rowDataArgs=rowDataArgs, customDataArgs=customDataArgs,
    redDimMax = 1, colDataMax = 0, featAssayMax = 0, rowDataMax = 1, sampAssayMax = 0, rowStatMax = 0, colStatMax = 0, customDataMax = 1, heatMapMax = 0, customStatMax = 0,
    initialPanels=initialPanels,
    customDataFun=list(CUSTOM_MULTI=CUSTOM_MULTI), tour=tour, appTitle = "Custom table panel: Log fold-change (cached)")

# launch the app itself ----

runApp(app)
