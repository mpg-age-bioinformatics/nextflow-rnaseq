#!/bin/bash

cp ${1} project.config

## need to add the different repos as submodule 
## first time
# cd ~/flaski-3.0.0
# git submodule add git@github.com:mpg-age-bioinformatics/pyflaski.git pyflaski
# git submodule init pyflaski
## fresh clone
# cd ~/flaski-3.0.0
# git submodule update --init --recursive
## update
# git submodule update --recursive --remote
## Commiting changes:
# cd ~/flaski-3.0.0/pyflaski
# git add -A . 
# git commit -m "<describe your changes here>"
# git push origin HEAD:master
## then tell the main project to start tracking the updated version:
# cd ~/flaski-3.0.0
# git add pyflaski
# git commit -m pyflaski
# git push

for f in nf-fastqc nf-kallisto nf-featurecounts nf-multiqc nf-deseq2 ;
  do
    if [ -d ${f} ] 
      then
        cd ${f}
        current=$(git rev-parse --short HEAD)
        git restore .
        git pull
        new=$(git rev-parse --short HEAD)
        cd ../
        if [[ "${current}" != "${new}"  ]] ; then echo "$(date) | ${f} | ${new}" >> dependencies.log
      else
        git clone git@github.com:mpg-age-bioinformatics/${f}.git
        cd ../
    fi
    cd ${f}
    rm -rf project.config
    ln -s ../project.config project.config
    cd ..
done

nextflow run nf-fastqc && \
nextflow run nf-kallisto/1_get_genome && \
nextflow run nf-kallisto/2_write_cdna && \
nextflow run nf-kallisto/3_index && \
nextflow run nf-kallisto/4_check_strand && \
nextflow run nf-kallisto/5_mapping && \
nextflow run nf-featurecounts && \
nextflow run nf-multiqc && \
nextflow run nf-deseq2/1_preprocess && \
nextflow run nf-deseq2/2_pair-wise && \
nextflow run nf-deseq2/3_annotate && \
nextflow run nf-deseq2/4_david && \
nextflow run nf-deseq2/5_topgo && \
nextflow run nf-deseq2/6_cellplots && \
nextflow run nf-deseq2/7_rcistarget



