#' ---
#' title: "FLowering Time Induction Biological QA"
#' author: "Nicolas Delhomme & Jesús Praena"
#' date: "`r Sys.Date()`"
#' output:
#'  html_document:
#'    toc: true
#'    number_sections: true
#'    code_folding: hide
#' ---
#' # Setup
#' * Libraries
suppressPackageStartupMessages({
  library(data.table)
  library(DESeq2)
  library(gplots)
  library(here)
  library(hyperSpec)
  library(parallel)
  library(pander)
  library(plotly)
  library(RColorBrewer)
  library(tidyverse)
  library(tximport)
  library(vsn)
})

#' * Helper functions
source(here("UPSCb-common/src/R/featureSelection.R"))

#' * Graphics
pal <- brewer.pal(8,"Dark2")
hpal <- colorRampPalette(c("blue","white","red"))(100)
mar <- par("mar")

#' * Metadata
#' Sample information
#' ```{r CHANGEME1,eval=FALSE,echo=FALSE}
#' # The csv file should contain the sample information, including the sequencing file name, 
#' # any relevant identifier, and the metadata of importance to the study design
#' # as columns, e.g. the SamplingTime for a time series experiment
#'  ```
samples <- read_csv(here("doc/variables.csv"),
                      col_types=cols(
                        col_character(),
                        col_factor(),
                        col_factor(),
                        col_factor(),
                        col_factor()
                      ))

#' # Raw data
#' tx2gene translation table
#' ```{r CHANGEME2,eval=FALSE,echo=FALSE}
#' # This file is necessary if your species has more than one transcript per gene.
#' #
#' # It should then contain two columns, tab delimited, the first one with the transcript
#' # IDs and the second one the corresponding
#' #
#' # If your species has only one transcript per gene, e.g. Picea abies v1, then
#' # comment the next line
#' ```
tx2gene <- suppressMessages(read_delim(here("reference/annotation/tx2gene.txt"),delim="\t",
                                       col_names=c("TXID","GENE")))

#' # Raw data
filelist <- list.files(here("data/salmon"), 
                       recursive = TRUE, 
                       pattern = "quant.sf",
                       full.names = TRUE)

#' Sanity check to ensure that the data is sorted according to the sample info
#' ```{r CHANGEME3,eval=FALSE,echo=FALSE}
#' # This step is to validate that the salmon files are inthe same order as 
#' # described in the samples object. If not, then they need to be sorted
#' ````
names(filelist) <- sub("_S\\d+.*","",basename(dirname(filelist)))
stopifnot(all(samples$ID==names(filelist)))

#' Read the expression at the gene level
#' ```{r CHANGEME4,eval=FALSE,echo=FALSE}
#' If the species has only one transcript per gene, replace with the following
#' counts <- suppressMessages(round(tximport(files = filelist, type = "salmon",txOut=TRUE)$counts))
#' ```
#' This gives us directly gene counts
txi <- suppressMessages(tximport(files = filelist, 
                                 type = "salmon",
                                 tx2gene=tx2gene))
counts <- round(txi$counts)

# counts <- summarizeToGene(tx,tx2gene=tx2gene)

#' ## Quality Control
#' * Check how many genes are never expressed
sel <- rowSums(counts) == 0
sprintf("%s%% percent (%s) of %s genes are not expressed",
        round(sum(sel) * 100/ nrow(counts),digits=1),
        sum(sel),
        nrow(counts))

#' * Let us take a look at the sequencing depth, colouring by CHANGEME
#' ```{r CHANGEME5,eval=FALSE,echo=FALSE}
#' # In the following most often you need to replace CHANGEME by your
#' # variable of interest, i.e. the metadata represented as column in
#' # your samples object, e.g. SamplingTime
#' ```
dat <- tibble(x=colnames(counts),y=colSums(counts)) %>% 
  bind_cols(samples)

ggplot(dat,aes(x,y,fill=TISSUE)) + geom_col() + 
  scale_y_continuous(name="reads") +
  theme(axis.text.x=element_text(angle=90,size=4),axis.title.x=element_blank())

#' * Display the per-gene mean expression
#' 
#' _i.e._ the mean raw count of every gene across samples is calculated
#' and displayed on a log10 scale.
#' 
#' The cumulative gene coverage is as expected
ggplot(data.frame(value=log10(rowMeans(counts))),aes(x=value)) + 
  geom_density() + ggtitle("gene mean raw counts distribution") +
  scale_x_continuous(name="mean raw counts (log10)")

#' Also removing P14065_119
ggplot(data.frame(value=log10(rowMeans(counts[,colnames(counts)!="P14065_119"]))),aes(x=value)) + 
  geom_density() + ggtitle("gene mean raw counts distribution") +
  scale_x_continuous(name="mean raw counts (log10)")

#' The same is done for the individual samples colored by CHANGEME. 
#' ```{r CHANGEME6,eval=FALSE,echo=FALSE}
#' # In the following, the second mutate also needs changing, I kept it 
#' # as an example to illustrate the first line. SampleID would be 
#' # a column in the samples object (the metadata) that uniquely indentify
#' # the samples.
#' # If you have only a single metadata, then remove the second mutate call
#' # If you have more, add them as needed.
#' ```
dat <- as.data.frame(log10(counts)) %>% utils::stack() %>% 
  mutate(TISSUE=samples$TISSUE[match(ind,samples$ID)]) %>% 
  mutate(TIME=samples$TIME[match(ind,samples$ID)]) %>% 
  mutate(TREATMENT=samples$TREATMENT[match(ind,samples$ID)])

ggplot(dat,aes(x=values,group=ind,col=TISSUE)) + 
  geom_density() + ggtitle("sample raw counts distribution") +
  scale_x_continuous(name="per gene raw counts (log10)")

#' Removing P14065_119
dat <- as.data.frame(log10(counts[,colnames(counts)!="P14065_119"])) %>% utils::stack() %>% 
  mutate(TISSUE=samples$TISSUE[match(ind,samples$ID)]) %>% 
  mutate(TIME=samples$TIME[match(ind,samples$ID)]) %>% 
  mutate(TREATMENT=samples$TREATMENT[match(ind,samples$ID)])

ggplot(dat,aes(x=values,group=ind,col=TISSUE)) + 
  geom_density() + ggtitle("sample raw counts distribution") +
  scale_x_continuous(name="per gene raw counts (log10)")

#' ## Export
dir.create(here("data/analysis/salmon"),showWarnings=FALSE,recursive=TRUE)
write_csv(as.data.frame(counts) %>% rownames_to_column("ID"),
          here("data/analysis/salmon/raw-unormalised-gene-expression_data.csv"))

#' # Data normalisation 
#' ## Preparation
#' For visualization, the data is submitted to a variance stabilization
#' transformation using DESeq2. The dispersion is estimated independently
#' of the sample tissue and replicate. 
#'  
#'  ```{r CHANGEME7,eval=FALSE,echo=FALSE}
#'  # In the following, we provide the expected expression model, based on the study design.
#'  # It is technically irrelevant here, as we are only doing the quality assessment of the data, 
#'  # but it does not harm setting it correctly for the differential expression analyses that may follow.
#'  ```
dds <- DESeqDataSetFromTximport(
  txi=txi,
  colData = samples,
  design = ~ TISSUE * CONDITION)

#' ## Remove bad sample 
dds <- dds[,-match("P14065_119",colnames(dds))]

save(dds,file=here("data/analysis/salmon/dds.rda"))

#' Check the size factors (_i.e._ the sequencing library size effect)
#' 
#' There is some variation -/+ 50%, but that's acceptable
dds <- estimateSizeFactors(dds)
sizes <- sizeFactors(dds)
pander(sizes)
boxplot(sizes, main="Sequencing libraries size factor")
abline(h=1,lty=2,col="grey")

#' ## Variance Stabilising Transformation
vsd <- varianceStabilizingTransformation(dds, blind=TRUE)
vst <- assay(vsd)
vst <- vst - min(vst)

#' * Validation
#' 
#' The variance stabilisation worked adequately
#' 
meanSdPlot(vst[rowSums(vst)>0,])

#' ## QC on the normalised data
#' ### PCA
pc <- prcomp(t(vst))
percent <- round(summary(pc)$importance[2,]*100)

#' * Cumulative components effect
#' 
#' We define the number of variable of the model
nvar=2

#' An the number of possible combinations
nlevel=nlevels(dds$TISSUE) * nlevels(dds$CONDITION)

#' We plot the percentage explained by the different components, the
#' red line represent the number of variable in the model, the orange line
#' the number of variable combinations.
ggplot(tibble(x=1:length(percent),y=cumsum(percent)),aes(x=x,y=y)) +
  geom_line() + scale_y_continuous("variance explained (%)",limits=c(0,100)) +
  scale_x_continuous("Principal component") + 
  geom_vline(xintercept=nvar,colour="red",linetype="dashed",size=0.5) + 
  geom_hline(yintercept=cumsum(percent)[nvar],colour="red",linetype="dashed",size=0.5) +
  geom_vline(xintercept=nlevel,colour="orange",linetype="dashed",size=0.5) + 
  geom_hline(yintercept=cumsum(percent)[nlevel],colour="orange",linetype="dashed",size=0.5)
  
#' ### 2D
#' The most variance comes from the tissues. In the leaf, the time has more effect than the 
#' treatment, while this look the opposite in the apex.
pc.dat <- bind_cols(PC1=pc$x[,1],
                    PC2=pc$x[,2],
                    as.data.frame(colData(dds)))

p <- ggplot(pc.dat,aes(x=PC1,y=PC2,col=CONDITION,shape=TISSUE,text=ID)) + 
  geom_point(size=2) + 
  ggtitle("Principal Component Analysis",subtitle="variance stabilized counts")

ggplotly(p) %>% 
  layout(xaxis=list(title=paste("PC1 (",percent[1],"%)",sep="")),
         yaxis=list(title=paste("PC2 (",percent[2],"%)",sep="")))

#' ### Heatmap
#' 
#' Filter for noise
#' 
conds <- factor(paste(dds$TISSUE,dds$CONDITION))
sels <- rangeFeatureSelect(counts=vst,
                           conditions=conds,
                           nrep=3)
vst.cutoff <- 2

#' * Heatmap of "all" genes
#' 
hm <- heatmap.2(t(scale(t(vst[sels[[vst.cutoff+1]],]))),
                distfun=pearson.dist,
                hclustfun=function(X){hclust(X,method="ward.D2")},
                labRow = NA,trace = "none",
                labCol = conds,
                col=hpal)

plot(as.hclust(hm$colDendrogram),xlab="",sub="",labels=paste(dds$ID,conds),cex=0.6)

#' ## Conclusion
#' The main differences in the leaf samples are according to the days of sampling. 
#' The new T1 dexa samples cluster in T1 with a cluster of T1 havin both mock and Dexa.
#' It would seem generally that the effect of Dexa vs. Mock in leaf at T1 is minimal.
#' 
#' For appices, the situation is somewhat different, the time and treatment seem to be both of
#' importance. T0 samples merged with T1 dexa while T1 mock form its own cluster, possibly indicating a
#' delay induced by the treatment. The newer samples form their own clusters, possibly indicating that 
#' a batch effect (most likely due to sampling rather than sequencing as the leaf sample do not show such an effect)
#' has a stronger influence than the biological signal. At T3 there is a clear separation between mock and dexa.
#' 
#' With regards to the batch observed in the new appices samples, it is however probably marginal as it is not visible in the
#' first 2 dimension of the PCA, that contribute 80% of the variance. So it will be within the whole dataset 
#' at most 3%. If anything, assuming the effect is due to the sampling, hence biological noise, it would only make the 
#' comparison more robust.
#' ```{r empty,eval=FALSE,echo=FALSE}
#' ```
#'
#' # Session Info
#' ```{r session info, echo=FALSE}
#' sessionInfo()
#' ```
