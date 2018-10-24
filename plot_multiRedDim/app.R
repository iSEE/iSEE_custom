
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
         log = list(x = NULL, y = NULL), direction = "xy",
         brushId = "redDimPlot1_Brush", outputId = "redDimPlot1"))

colDataArgs <- colDataPlotDefaults(sce, 1)
colDataArgs$XAxis <- "Column data"
colDataArgs$XAxisColData <- "driver_1_s"
colDataArgs$YAxis <- "Core.Type"

customDataArgs <- customDataPlotDefaults(sce, 1)
customDataArgs$Function <- "CUSTOM_MULTI"
customDataArgs$ColumnSource <- "Reduced dimension plot 1"
customDataArgs$RowSource <- "Row data plot 1"
customDataArgs$SelectBoxOpen <- TRUE

initialPanels <- DataFrame(
    Name=c("Reduced dimension plot 1", "Column data plot 1", "Custom data plot 1"),
    Width=c(6L, 6L, 12L))

app <- iSEE(
    se = sce,
    redDimArgs=redDimArgs, colDataArgs=colDataArgs, customDataArgs=customDataArgs,
    redDimMax = 1, colDataMax = 1, featAssayMax = 0, rowDataMax = 0, sampAssayMax = 0, rowStatMax = 0, colStatMax = 0, customDataMax = 1, heatMapMax = 0, customStatMax = 0,
    initialPanels=initialPanels,
    customDataFun=list(CUSTOM_MULTI=CUSTOM_MULTI), tour=tour, appTitle = "Custom plot panel: Multiple reduced dimensions")

# launch the app itself ----

runApp(app)
