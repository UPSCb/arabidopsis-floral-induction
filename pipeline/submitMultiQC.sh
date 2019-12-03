#!/bin/bash

#set -ex

proj=u2019009
mail=noemi.skorzinski@umu.se
in="/mnt/picea/projects/arabidopsis/mschmid/NS-tps1-kin10-snf4/"
out="/mnt/picea/projects/arabidopsis/mschmid/NS-tps1-kin10-snf4/multiqc"

if [ ! -d $out ]; then
	mkdir -p $out
fi

module load bioinfo-tools multiqc

sbatch --mail-user=$mail -o $in/multiqc.out -e $in/multiqc.err -A $proj ../UPSCb-common/pipeline/runMultiQC.sh $in $out
