#!/bin/bash -l
in=../data/raw/peptide.faa
db=../reference/indices/BLAST+/TAIR
out=../data/BLAST+

if [ ! -d $out ]; then
  mkdir $out
fi

sbatch -p nolimit -t unlimited -n 12 -A u2019022 \
-o $out/peptide-TAIR10.out -e $out/peptide-TAIR10.err \
../UPSCb-common/pipeline/runBlastPlus.sh -p 12 -e 10 tblastn $in $db $out  