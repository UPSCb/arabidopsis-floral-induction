#!/bin/bash -l

set -eu

proj=u2019022
mail=nicolas.delhomme@umu.se

in=$(realpath ../data/raw)
out=$(realpath ../data)
start=2
end=6

#module load bioinfo-tools FastQC Trimmomatic sortmerna
module load bioinfo-tools trimmomatic
THOME=$TRIMMOMATIC_HOME
export PATH=$PATH:$HOME/Git/kogia/scripts
module unload trimmomatic
export TRIMMOMATIC_HOME=$THOME
module load SortMeRNA java

echo $PATH
echo $TRIMMOMATIC_HOME
echo $(which sortmerna)
echo $(which awk)
echo $(which trimmomatic)

for f in $(find $in -name "*_1.fastq.gz");
do
  fnam=$(basename ${f/_1.fastq.gz/})
  bash -l $(realpath ../UPSCb-common/pipeline/runRNASeqPreprocessing.sh) -s $start -e $end \
  $proj $mail $f $in/${fnam}_2.fastq.gz $out
done
