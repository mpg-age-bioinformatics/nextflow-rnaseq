#!/bin/bash

## usage:
## $1 : `release` for latest nextflow/git release; `checkout` for git clone followed by git checkout of a tag ; `clone` for latest repo commit
## $2 : /path/to/params.json

set -e

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

PROFILE=local
LOGS="work"
PARAMS="${2}"

mkdir -p ${LOGS}

if [[ "$1" == "release" ]] ; 
  then

    ORIGIN="mpg-age-bioinformatics/"
    
    FASTQC_RELEASE=$(get_latest_release ${ORIGIN}nf-fastqc)
    echo "${ORIGIN}nf-fastqc:${FASTQC_RELEASE}" >> ${LOGS}/software.txt
    FASTQC_RELEASE="-r ${FASTQC_RELEASE}"
    
    KALLISTO_RELEASE=$(get_latest_release ${ORIGIN}nf-kallisto)
    echo "${ORIGIN}nf-kallisto:${KALLISTO_RELEASE}" >> ${LOGS}/software.txt
    KALLISTO_RELEASE="-r ${KALLISTO_RELEASE}"
    
    FEATURECOUNTS_RELEASE=$(get_latest_release ${ORIGIN}nf-featurecounts)
    echo "${ORIGIN}nf-featurecounts:${FEATURECOUNTS_RELEASE}" >> ${LOGS}/software.txt
    FEATURECOUNTS_RELEASE="-r ${FEATURECOUNTS_RELEASE}"
    
    MULTIQC_RELEASE=$(get_latest_release ${ORIGIN}nf-multiqc)
    echo "${ORIGIN}nf-multiqc:${MULTIQC_RELEASE}" >> ${LOGS}/software.txt
    MULTIQC_RELEASE="-r ${MULTIQC_RELEASE}"
    
    DESEQ2_RELEASE=$(get_latest_release ${ORIGIN}nf-deseq2)
    echo "${ORIGIN}nf-deseq2:${DESEQ2_RELEASE}" >> ${LOGS}/software.txt
    DESEQ2_RELEASE="-r ${DESEQ2_RELEASE}"
    
    uniq ${LOGS}/software.txt ${LOGS}/software.txt_
    mv ${LOGS}/software.txt_ ${LOGS}/software.txt
    
else

  for repo in nf-fastqc  nf-kallisto nf-featurecounts nf-multiqc nf-deseq2   ; 
    do

      if [[ ! -e ${repo} ]] ;
        then
          git clone git@github.com:mpg-age-bioinformatics/${repo}.git
      fi

      if [[ "$1" == "checkout" ]] ;
        then
          cd ${repo}
          git pull
          RELEASE=$(get_latest_release ${ORIGIN}${repo})
          git checkout ${RELEASE}
          cd ../
          echo "${ORIGIN}${repo}:${RELEASE}" >> ${LOGS}/software.txt
      else
        cd ${repo}
        COMMIT=$(git rev-parse --short HEAD)
        cd ../
        echo "${ORIGIN}${repo}:${COMMIT}" >> ${LOGS}/software.txt
      fi

  done

  uniq ${LOGS}/software.txt >> ${LOGS}/software.txt_ 
  mv ${LOGS}/software.txt_ ${LOGS}/software.txt

fi

get_images() {
  echo "- downloading images"
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-featurecounts ${FEATURECOUNTS_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1
}

run_fastqc() {
  echo "- running fastqc"
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1 && \
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1
}

run_kallisto() {
  echo "- running kallisto"
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file ${PARAMS} -entry get_genome -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file ${PARAMS} -entry write_cdna -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file ${PARAMS} -entry index -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file ${PARAMS} -entry check_strand -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file ${PARAMS} -entry map_reads -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1
}

run_featurecounts_and_multiqc() {
  echo "- running featurecounts" && \
  nextflow run ${ORIGIN}nf-featurecounts ${FEATURECOUNTS_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/featurecounts.log 2>&1 && \
  echo "- running multiqc" && \
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/multiqc.log 2>&1 && \
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/multiqc.log 2>&1
}

run_deseq2() {
  echo "- running deseq2" && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry preprocess -profile ${PROFILE} >> ${LOGS}/deseq2.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry pairwise -profile ${PROFILE} >> ${LOGS}/deseq2.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry annotate -profile ${PROFILE} >> ${LOGS}/deseq2.log 2>&1
}

run_enrichments() {
  echo "- running enrichments"
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry david -profile ${PROFILE} >> ${LOGS}/enrichments.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry topgo -profile ${PROFILE} >> ${LOGS}/enrichments.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry cellplots -profile ${PROFILE} >> ${LOGS}/enrichments.log 2>&1
}

get_images && \
run_fastqc && \
run_kallisto && \
run_featurecounts_and_multiqc && \
run_deseq2 && \
run_enrichments && \
echo "- running rcistarget" && \
nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry rcistarget -profile ${PROFILE} >> ${LOGS}/rcistarget.log 2>&1 && \
echo "- running qc" && \
nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry qc -profile ${PROFILE} >> ${LOGS}/qc.log 2>&1 && \
echo "- running cytoscape" && \
nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry string_cytoscape -profile ${PROFILE} >> ${LOGS}/string_cytoscape.log 2>&1 && \
nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/deseq2.log 2>&1 && \

LOGS=$(readlink -f ${LOGS})
project_folder=$(grep project_folder ${PARAMS} | awk -F\" '{print $4}' )
eval cd ${project_folder}
rm -rf upload.txt
cat $(find . -name upload.txt) > upload.txt
mkdir -p summary
while read line ; 
  do 
    folder=$(echo ${line} | awk '{ st = index($0," ");print $1}')
    ref=$(echo ${line} | awk '{ st = index($0," ");print substr($0,st+1)}')
    if [[ "${folder}" != "main" ]] ;
      then
        target=summary/${folder}/$(basename ${ref})
        mkdir -p summary/${folder}
    else
      target=summary/$(basename ${ref})
    fi
  ln -s ${ref} ${target}
done < upload.txt

echo "- done"
exit