#' ---
#' title: "Mfuzz clustering"
#' author: "CHANGEME"
#' date: "`r Sys.Date()`"
#' output:
#'  html_document:
#'    toc: true
#'    number_sections: true
#' ---
#' # Setup

#' * Libraries
suppressPackageStartupMessages({
  library(here)
  library(matrixStats)
  library(Mfuzz)
  library(readr)
})

suppressMessages(source(here("UPSCb-common/src/R/featureSelection.R")))
suppressMessages(source(here("UPSCb-common/src/R/gopher.R")))

#' * data
load(here("data/analysis/DE/salmon-vst-aware.rda"))

#' sample info
samples <- read_csv(here("doc/variables.csv"),
                    col_types=cols(
                      col_character(),
                      col_factor(),
                      col_factor(),
                      col_factor(),
                      col_factor()
                    ))


#' # Fuzzy clustering
#' ##Prep
#' Create the eset
conds <- apply(samples[match(colnames(vst),samples$ID),
                       c("TISSUE","TIME","TREATMENT")],
               1,paste,collapse="-")
eset <- ExpressionSet(sapply(split.data.frame(t(vst),conds),colMeans))

#' Remove genes with too little a variation
#' 
#' First we look at the SD distribution
plot(density(rowSds(vst)))
plot(density(rowSds(vst)),xlim=c(-0.2,0.5))

#' A cutoff at 0.1 seems adequate
eset <- filter.std(eset,min.std=0.1)

#' Standardise the values
eset <- standardise(eset) 

#' ## Clustering
#' parameter estimation

m1 <- mestimate(eset)

#' cluster
cl <- mfuzz(eset,m1,c=24)

#' ##Plot
colnames(eset)
dir.create(here("data/analysis/Mfuzz"),showWarnings = FALSE)
pdf(file=here("data/analysis/Mfuzz/clusters24.pdf"),width = 16,height=24)
mfuzz.plot2(eset,cl,x11 = FALSE,mfrow=c(3,4),time.labels = colnames(eset),
            centre = TRUE,las=2)
dev.off()

#' ##Membership
str(cl)
barplot(cl$size)

# genes for cluster 20
names(cl$cluster)[cl$cluster == 20]

background <- rownames(vst)[featureSelect(vst,samples[match(colnames(vst),samples$ID),"CONDITION"],exp=0.5)]

enr.list <- lapply(1:length(cl$size),function(i,clc){
  lapply(names(clc)[clc==i],gopher,background=background,task="go",url="athaliana")
},cl$cluster)

# cluster membership
rowMax(cl$membership)

plot(density(cl$membership[cl$cluster == 20,20]))

names(cl$cluster)[cl$cluster == 20][cl$membership[cl$cluster == 20,20] >= 0.75]

#' # Session Info 
#'  ```{r session info, echo=FALSE}
#'  sessionInfo()
#'  ```
