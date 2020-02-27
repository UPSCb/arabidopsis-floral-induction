#' ---
#' title: "Transcript vs gene DE"
#' author: "Nicolas Delhomme"
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
  library(tidyverse)
  library(RColorBrewer)
  library(VennDiagram)
})

#' * graphics
pal <- brewer.pal(4,"Dark2")

#' # Venn
#' ## Apex
apex <- suppressMessages(suppressWarnings(list(
  T1g=read_csv(here("data/analysis/DE/Salmon-Apex_Dexa-vs-Mock_T1_genes.csv")) %>% select(X1) %>% unlist(use.names=FALSE),
  T1t=read_csv(here("data/analysis/DE/Salmon-Tx_Apex_Dexa-vs-Mock_T1_transcripts.csv")) %>% select(X1) %>% 
    unlist(use.names=FALSE) %>% sub(pattern="\\.[0-9]+$",replacement=""),
  T3g=read_csv(here("data/analysis/DE/Salmon-Apex_Dexa-vs-Mock_T3_genes.csv")) %>% select(X1) %>% unlist(use.names=FALSE),
  T3t=read_csv(here("data/analysis/DE/Salmon-Tx_Apex_Dexa-vs-Mock_T3_transcripts.csv")) %>% select(X1) %>% 
    unlist(use.names=FALSE) %>% sub(pattern="\\.[0-9]+$",replacement="")
)))

grid.newpage()
grid.draw(venn.diagram(apex,NULL,fill=pal))

#' ## Leaf
leaf <- suppressMessages(suppressWarnings(list(
  T1g=read_csv(here("data/analysis/DE/Salmon-Leaf_Dexa-vs-Mock_T1_genes.csv")) %>% select(X1) %>% unlist(use.names=FALSE),
  T1t=read_csv(here("data/analysis/DE/Salmon-Tx_Leaf_Dexa-vs-Mock_T1_transcripts.csv")) %>% select(X1) %>% 
    unlist(use.names=FALSE) %>% sub(pattern="\\.[0-9]+$",replacement=""),
  T3g=read_csv(here("data/analysis/DE/Salmon-Leaf_Dexa-vs-Mock_T3_genes.csv")) %>% select(X1) %>% unlist(use.names=FALSE),
  T3t=read_csv(here("data/analysis/DE/Salmon-Tx_Leaf_Dexa-vs-Mock_T3_transcripts.csv")) %>% select(X1) %>% 
    unlist(use.names=FALSE) %>% sub(pattern="\\.[0-9]+$",replacement="")
)))

grid.newpage()
grid.draw(venn.diagram(leaf,NULL,fill=pal))

#' # Session Info 
#'  ```{r session info, echo=FALSE}
#'  sessionInfo()
#'  ```


