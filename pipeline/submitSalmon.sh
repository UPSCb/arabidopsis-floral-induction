#!/bin/bash -l

## be verbose and print
set -eux

proj=u2019022
mail=nicolas.delhomme@umu.se

in=$(realpath ../data/trimmomatic)
out=$(realpath ../data/salmon)
ref=$(realpath ../reference/indices/salmon/Araport11_all-201606_salmon-v14dot1.inx)
bind=/mnt:/mnt
img=$(realpath ../singularity/salmon-0.14.1.simg)

## create the out dir
if [ ! -d $out ]; then
    mkdir -p $out
fi

## for every file
for f in $(find $in -name "*_trimmomatic_1.fq.gz"); do
  fnam=$(basename ${f/_1.fq.gz/})

  ## execute
 sbatch -A $proj --mail-user=$mail \
  -e $out/$fnam.err -o $out/$fnam.out -J salmon.$fnam \
  ../UPSCb-common/pipeline/runSalmon.sh -b $bind \
  -i $img $ref $f $in/${fnam}_2.fq.gz $out
done
