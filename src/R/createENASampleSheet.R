library(here)
library(readr)
library(tibble)

tb <- read_csv(here("doc/variables.csv"))

title <- "Characterisation of metabolic changes associated with floral transition in Arabidopsis: variations in raffinose synthesis contribute to the determination of flowering time."

files=scan(here("doc/raw_files.txt"),what="character")

md5 <- read_delim(here("doc/raw_files.md5"),
                  col_names=c("MD5","File"),
                  show_col_types=FALSE)

md5 <- md5[match(md5$File,substr(files,8,nchar(files))),]

stopifnot(all(md5$File == substr(files,8,nchar(files))))

ena <- tibble(ExperimentTitle=rep(title,nrow(tb)*2),
              SampleName=rep(tb$ID,each=2),
              SampleDescription=rep(paste(tolower(tb$TISSUE),
                                          "collected at",
                                          tb$TIME,"upon",
                                          tb$TREATMENT,"treatment"),each=2),
              SequencingDate=rep(rep(c("2019-11-29T10:00:00","2020_11_20T10:00:00"),
                                     c(sum(grepl("P14",tb$ID)),sum(grepl("P17",tb$ID)))),each=2),
              FileName=basename(files),
              FileLocation=dirname(files),
              MD5checksum=md5$MD5)

write_csv(ena,here("../UPSCb/ENA/submission/ENA-submission-UPSC-0258.csv"))
