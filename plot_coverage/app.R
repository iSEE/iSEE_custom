suppressPackageStartupMessages({
    library(iSEE)
    library(tidyr)
})
options(ucscChromosomeNames = FALSE)

# Import custom panel ---
source("custom.R")

# Import gtf file and save as GRanges object ---
gtf <- rtracklayer::import("Homo_sapiens.GRCh38.93.1.1.10M.gtf")
idx <- match(c("transcript_id", "gene_id", "exon_id"),
             colnames(S4Vectors::mcols(gtf)))
colnames(S4Vectors::mcols(gtf))[idx] <- c("transcript", "gene", "exon")
if (!("gene_name" %in% colnames(S4Vectors::mcols(gtf)))) {
    gtf$gene_name <- gtf$gene
}
gtf <- BiocGenerics::subset(gtf, type == "exon")
gtf$transcript <- gsub("\\.[0-9]+$", "", gtf$transcript)
gtf$gene <- gsub("\\.[0-9]+$", "", gtf$gene)
saveRDS(gtf, file = "Homo_sapiens.GRCh38.93.1.1.10M.granges.rds")

# Import SCE object ---
# This object was obtained by running the ARMOR workflow
# (https://github.com/csoneson/ARMOR) on the example data provided therein. The
# final output of the workflow is a SingleCellExperiment object containing
# estimated gene-level abundances as well as metadata and results from
# statistical tests. In addition, bigwig files are generated for all samples
# based on alignment of the reads to the reference genome.
sce <- readRDS("shiny_sce.rds")$sce_gene
rownames(sce) <- sapply(strsplit(rownames(sce), "__"), .subset, 1)
rowData(sce) <- tidyr::unnest(as.data.frame(rowData(sce)))

# Configure the app ---
cdp <- customDataPlotDefaults(sce, 1)
cdp$Function <- "CUSTOM_GVIZ"
cdp$Arguments <- c("bigwig_files SRR1039508.bw,SRR1039512.bw\n bigwig_names SRR1039508,SRR1039512\nbigwig_conditions N61311,N052611\ngranges Homo_sapiens.GRCh38.93.1.1.10M.granges.rds\nchr 1\nstart 6.1e6\nend 6.2e6\nshowgene DDX11L1")
cdp$RowSource <- "Row data plot 1"

rdp <- rowDataPlotDefaults(sce, 5)
rdp$YAxis <- "edgeR.cellineN61311.cellineN052611.mlog10PValue"
rdp$XAxis <- "Row data"
rdp$XAxisRowData <- "edgeR.cellineN61311.cellineN052611.logFC"

tour <- read.delim("tour.txt", sep = ";", quote = "")
app <- iSEE(sce,
            rowDataArgs = rdp,
            customDataArgs = cdp,
            customDataFun = list(CUSTOM_GVIZ = CUSTOM_GVIZ),
            initialPanels = DataFrame(
                Name = c("Row data plot 1", "Custom data plot 1"),
                Width = c(4, 8)),
            tour = tour)

shiny::runApp(app)
