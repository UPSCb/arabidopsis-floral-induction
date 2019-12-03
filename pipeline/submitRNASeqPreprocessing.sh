#!/bin/bash -l

set -eux

proj=u2019009
mail=noemi.skorzinski@umu.se

in=/mnt/picea/projects/arabidopsis/mschmid/NS-tps1-kin10-snf4/raw
out=/mnt/picea/projects/arabidopsis/mschmid/NS-tps1-kin10-snf4
start=2
end=6

module load bioinfo-tools FastQC Trimmomatic sortmerna

for f in $(find $in -name "*_1.fq.gz"); 
do
  fnam=$(basename ${f/_1.fq.gz/})
  bash ../UPSCb-common/pipeline/runRNASeqPreprocessing.sh -s $start -e $end \
  $proj $mail $f $in/${fnam}_2.fq.gz $out
done
