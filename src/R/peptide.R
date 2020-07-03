#' ---
#' title: "FLowering Time Induction Peptide analysis"
#' author: "Nicolas Delhomme"
#' date: "`r Sys.Date()`"
#' output:
#'  html_document:
#'    toc: true
#'    number_sections: true
#' ---

#' # Setup
suppressPackageStartupMessages({
  library(Biostrings)
  library(genomeIntervals)
  library(GenomicRanges)
  library(here)
  library(readr)
})

source(here("UPSCb-common/src/R/blastUtilities.R"))

#' * Data
aa <- read_tsv(here("doc/Peptide_list_RBenlloch.txt"),col_types=cols(Peptide=col_character()))
aaSet <- AAStringSet(unlist(aa))
writeXStringSet(aaSet,here("data/raw/peptide.faa"))

#' * Blast
blast <- readBlast(here("data/BLAST+/TAIR_peptide.blt"),format=BM8ext,plot=FALSE)

best.blast <- readBlast(here("data/BLAST+/TAIR_peptide.blt"),format=BM8ext,bestHit=TRUE,plot=FALSE)

#' * Gff
Araport11 <- readGff3(file=here("reference/gff3/Araport11_GFF3_genes_transposons.201606_synthetic-transcripts.gff3"),
                      quiet=TRUE)

genesGR <- as(Araport11[Araport11$type=="gene",],"GRanges")

#' # Results
message(sprintf("There are %s peptides mapping to the genome",length(unique(blast$df$query.id))))

#' * e-value distribution
#' Most of the alignment have an high e-value (>1) - i.e. < 0 in the boxplot below
boxplot(-log10(blast$blf$e.value),ylab="-log10 e-value")

#' # Analysis
#' Check for a gene overlap of the best blast hit
ovl <- findOverlaps(GRanges(seqnames=best.blast$blf$subject.id,
                             ranges=IRanges(start=ifelse(best.blast$blf$subject.start < best.blast$blf$subject.end,
                                                         best.blast$blf$subject.start,
                                                         best.blast$blf$subject.end),
                                            end=ifelse(best.blast$blf$subject.start > best.blast$blf$subject.end,
                                                       best.blast$blf$subject.start,
                                                       best.blast$blf$subject.end)),
                                            strand=ifelse(best.blast$blf$subject.start < best.blast$blf$subject.end,"+","-")),genesGR)
                     
res <- cbind(best.blast$blf[queryHits(ovl),],genesGR[subjectHits(ovl),c("ID","symbol","full_name")])

#' # Export
dir.create(here("data/analysis/peptides"),showWarnings=FALSE)
write_tsv(res,here("data/analysis/peptides/peptide-annotated-blast-results.tsv"))

#' # Session Info
#' ```{r session info, echo=FALSE}
#' sessionInfo()
#' ```
