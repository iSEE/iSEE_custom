suppressPackageStartupMessages({
    library(rtracklayer)
    library(BiocGenerics)
    library(IRanges)
    library(GenomicRanges)
    library(S4Vectors)
    library(Gviz)
})

#' Custom coverage plot
#'
#' Plot the coverage in a region of the genome, for a set of bigwig files.
#'
#' @param se A \code{SummarizedExperiment} object.
#' @param rows Selected rows (i.e., features).
#' @param columns Selected columns (i.e., samples).
#' @param bigwig_files Paths to bigwig files.
#' @param bigwig_names Names (e.g. sample IDs) for bigwig files.
#' @param bigwig_conditions Groups for bigwig files, used for coloring the coverage plots.
#' @param granges Path to .rds file containing GRanges object with gene annotations.
#' @param chr Chromosome to show. Ignored if \code{showgene} is not "".
#' @param start,end Start and end position of the region to show. Ignored if
#'   \code{showgene} is not "".
#' @param showgene Gene ID to show.
#'
#' @return A coverage plot
#'
#' @author Charlotte Soneson
#'
CUSTOM_GVIZ <- function(se, rows, columns, bigwig_files="", bigwig_names="",
                        bigwig_conditions="", granges="",
                        chr="", start="", end="", showgene="") {
    options(ucscChromosomeNames = FALSE)

    ## ---------------------------------------------------------------------- ##
    ## Pre-flight checks
    ## ---------------------------------------------------------------------- ##
    ## Must have at least one of bigwig_files and granges
    if (bigwig_files == "" && granges == "") {
        return(NULL)
    }

    ## If no names are given, assign names to bigwig files
    if (bigwig_files != "" && bigwig_names == "") {
        bigwig_names <- paste(paste0("S", seq_along(strsplit(bigwig_files, ",")[[1]])),
                              collapse = ",")
    }

    ## If granges file does not exist, don't show annotation
    if (!file.exists(granges)) {
        granges <- ""
    }

    ## If granges file does not exist, the viewing region must be set
    if (granges == "" && (chr == "" || start == "" || end == "")) {
        return(NULL)
    }

    ## Convert start and end positions to numeric values
    if (start != "") {
        start <- as.numeric(start)
    }
    if (end != "") {
        end <- as.numeric(end)
    }

    ## ---------------------------------------------------------------------- ##
    ## Prepare the annotation
    ## ---------------------------------------------------------------------- ##
    if (granges != "") {
        ## Read the GRanges object
        if (caching$granges == granges && !is.null(caching$gr0)) {
            gr0 <- caching$gr0
        } else {
            caching$gr0 <- readRDS(granges)
            caching$granges <- granges
            gr0 <- caching$gr0
        }

        ## Subset the GRanges object depending on the input
        ## If rows has length 1, overwrite any provided showgene
        if (length(rows) == 1) {
            showgene <- rows
        }

        ## Strip version number from the gene of interest if it exists
        showgene <- gsub("\\.[0-9]+$", "", showgene)

        if (showgene == "" && (chr == "" || is.na(start) || is.na(end))) {
            return(NULL)
        }

        ## If a gene has been defined (either via rows or via showgene), set the
        ## viewing range accordingly
        if (showgene != "") {
            gr <- BiocGenerics::subset(gr0, tolower(gene) == tolower(showgene) |
                                           tolower(gene_name) == tolower(showgene))
            ## Select only one gene if there are many with the same name
            gr <- BiocGenerics::subset(gr, gene == gene[1])
            chr <- unique(GenomeInfoDb::seqnames(gr))
            start <- min(BiocGenerics::start(gr))
            end <- max(BiocGenerics::end(gr))
        } else {
            gr <- gr0[IRanges::overlapsAny(
                gr0,
                GenomicRanges::GRanges(seqnames = chr,
                                       ranges = IRanges::IRanges(start = start,
                                                                 end = end),
                                       strand = "*")), ]
        }

        ## Other features in the region
        gro <- gr0[IRanges::overlapsAny(
            gr0,
            GenomicRanges::GRanges(seqnames = chr,
                                   ranges = IRanges::IRanges(start = start,
                                                             end = end),
                                   strand = "*"))]
        gro <- gro[!(S4Vectors::`%in%`(gro, gr))]

        grtr <- Gviz::GeneRegionTrack(gr, showId = TRUE, col = NULL, fill = "gray80",
                                      name = "Genes", col.title = "black")
        grtr2 <- Gviz::GeneRegionTrack(gro, showId = TRUE, col = "black", fill = "white",
                                       name = "", col.title = "black")
    } else {
        gr <- gro <- grtr <- grtr2 <- NULL
    }

    ## ---------------------------------------------------------------------- ##
    ## Set title and viewing range
    ## ---------------------------------------------------------------------- ##
    ## Define the title for the plot
    if (showgene != "" && !is.null(gr)) {
        if (all(gr$gene == gr$gene_name)) {
            plot_title <- unique(gr$gene)
        } else {
            plot_title <- unique(paste0(gr$gene, " (", gr$gene_name, ")"))
        }
    } else {
        plot_title <- paste0(chr, ":", start, "-", end)
    }

    ## Set min and max coord for the plot (add some padding to each side)
    minCoord <- start - 0.15*(end - start)
    maxCoord <- end + 0.05*(end - start)

    ## ---------------------------------------------------------------------- ##
    ## Prepare bigWig files
    ## ---------------------------------------------------------------------- ##
    ## Reformat bigWig file paths and names (provided to the function as
    ## character strings)
    if (bigwig_files != "") {
        bigwig_files <- strsplit(bigwig_files, ",")[[1]]
        bigwig_names <- strsplit(bigwig_names, ",")[[1]]
        if (bigwig_conditions != "") {
            bigwig_conditions <- strsplit(bigwig_conditions, ",")[[1]]
            names(bigwig_conditions) <- bigwig_names
        }
        names(bigwig_files) <- bigwig_names

        ## ---------------------------------------------------------------------- ##
        ## Define colors if bigwig_conditions is provided
        ## ---------------------------------------------------------------------- ##
        ## Define colors for coverage tracks
        color_list <- rep(c("#DC050C", "#7BAFDE", "#B17BA6", "#F1932D", "#F7EE55",
                            "#90C987", "#777777", "#E8601C", "#1965B0", "#882E72",
                            "#F6C141", "#4EB265", "#CAEDAB"),
                          ceiling(length(unique(bigwig_conditions))/13))

        if (length(bigwig_conditions) > 1 || bigwig_conditions != "") {
            usecol <- color_list[match(bigwig_conditions,
                                       unique(bigwig_conditions))]
        } else {
            usecol <- rep("gray", length(bigwig_files))
        }
        names(usecol) <- bigwig_names

        ## ------------------------------------------------------------------ ##
        ## Show only selected sample(s)
        ## ------------------------------------------------------------------ ##
        ## If columns is specified, subset bigwig files
        if (!is.null(columns)) {
            bigwig_files <- bigwig_files[columns]
            bigwig_conditions <- bigwig_conditions[columns]
            usecol <- usecol[columns]
        }

        ## ------------------------------------------------------------------ ##
        ## Prepare final plot
        ## ------------------------------------------------------------------ ##
        ## Set up coverage tracks
        tracks <- lapply(seq_along(bigwig_files), function(i) {
            assign(paste0("covtr", i),
                   Gviz::DataTrack(range = bigwig_files[i],
                                   type = "histogram",
                                   name = names(bigwig_files)[i],
                                   col.title = "black",
                                   fill = usecol[i],
                                   col = usecol[i],
                                   col.histogram = usecol[i],
                                   fill.histogram = usecol[i]))
        })
    } else {
        tracks <- NULL
    }

    ## Add genome axis track
    tracks <- c(tracks, Gviz::GenomeAxisTrack(), grtr, grtr2)

    ## Plot tracks
    Gviz::plotTracks(tracks, chromosome = chr, from = minCoord,
                     to = maxCoord, main = plot_title,
                     transcriptAnnotation = "transcript",
                     min.width = 0, min.distance = 0, collapse = FALSE)
}

# Set up a cache for the GRanges object
caching <- new.env()

