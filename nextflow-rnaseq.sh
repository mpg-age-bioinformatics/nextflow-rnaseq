#!/bin/bash

set -e

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

PROFILE=$1
LOGS=logs

if [[ "$2" != "clone" ]] ; 
  then

    ORIGIN="mpg-age-bioinformatics/"
    
    FASTQC_RELEASE=$(get_latest_release ${ORIGIN}nf-fastqc)
    echo "${ORIGIN}nf-fastqc:${FASTQC_RELEASE}" >> ${LOGS}/software.txt_
    FASTQC_RELEASE="-r ${FASTQC_RELEASE}"
    
    KALLISTO_RELEASE=$(get_latest_release ${ORIGIN}nf-kallisto)
    echo "${ORIGIN}nf-kallisto:${KALLISTO_RELEASE}" >> ${LOGS}/software.txt_
    KALLISTO_RELEASE="-r ${KALLISTO_RELEASE}"
    
    FEATURECOUNTS_RELEASE=$(get_latest_release ${ORIGIN}nf-featurecounts)
    echo "${ORIGIN}nf-featurecounts:${FEATURECOUNTS_RELEASE}" >> ${LOGS}/software.txt_
    FEATURECOUNTS_RELEASE="-r ${FEATURECOUNTS_RELEASE}"
    
    MULTIQC_RELEASE=$(get_latest_release ${ORIGIN}nf-multiqc)
    echo "${ORIGIN}nf-multiqc:${MULTIQC_RELEASE}" >> ${LOGS}/software.txt_
    MULTIQC_RELEASE="-r ${MULTIQC_RELEASE}"
    
    DESEQ2_RELEASE=$(get_latest_release ${ORIGIN}nf-deseq2)
    echo "${ORIGIN}nf-deseq2:${DESEQ2_RELEASE}" >> ${LOGS}/software.txt_
    DESEQ2_RELEASE="-r ${DESEQ2_RELEASE}"
    
    uniq ${LOGS}/upload.txt_ ${LOGS}/upload.txt 
    rm ${LOGS}/upload.txt_
    
else

  for repo in nf-fastqc nf-deseq2 nf-kallisto nf-featurecounts nf-multiqc nf-deseq2 ; 
    do

      if [[ ! -e ${repo} ]] ;
        then
          git clone git@github.com:mpg-age-bioinformatics/${repo}.git
      fi

  done

fi

mkdir -p ${LOGS}

get_images() {
  echo "- downloading images"
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file params.json -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file params.json -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-featurecounts ${FEATURECOUNTS_RELEASE} -params-file params.json -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -params-file params.json -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file params.json -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1
}

run_fastqc() {
  echo "- running fastqc"
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file params.json -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1 && \
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file params.json -entry upload -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1
}

run_kallisto() {
  echo "- running kallisto"
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file params.json -entry get_genome -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file params.json -entry write_cdna -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file params.json -entry index -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file params.json -entry check_strand -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file params.json -entry map_reads -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1
}

run_featurecounts_and_multiqc() {
  echo "- running featurecounts" && \
  nextflow run ${ORIGIN}nf-featurecounts ${FEATURECOUNTS_RELEASE} -params-file params.json -profile ${PROFILE} >> ${LOGS}/featurecounts.log 2>&1 && \
  echo "- running multiqc" && \
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -params-file params.json -profile ${PROFILE} >> ${LOGS}/multiqc.log 2>&1 && \
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -params-file params.json -entry upload -profile ${PROFILE} >> ${LOGS}/multiqc.log 2>&1
}

run_deseq2() {
  echo "- running deseq2" && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file params.json -entry preprocess -profile ${PROFILE} >> ${LOGS}/deseq2.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file params.json -entry pairwise -profile ${PROFILE} >> ${LOGS}/deseq2.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file params.json -entry annotate -profile ${PROFILE} >> ${LOGS}/deseq2.log 2>&1
}

run_enrichments() {
  echo "- running enrichments"
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file params.json -entry david -profile ${PROFILE} >> ${LOGS}/enrichments.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file params.json -entry topgo -profile ${PROFILE} >> ${LOGS}/enrichments.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file params.json -entry cellplots -profile ${PROFILE} >> ${LOGS}/enrichments.log 2>&1
}

get_images && sleep 1
run_fastqc & RUN_fastqc_PID=$!
sleep 1
run_kallisto & RUN_kallisto_PID=$!
sleep 1

for PID in $RUN_fastqc_PID $RUN_kallisto_PID ; 
    do
        wait -f $PID
        CODE=$?
        if [[ "$CODE" != "0" ]] ; 
            then
                exit $CODE
        fi
        
done

run_featurecounts_and_multiqc & RUN_featurecounts_and_multiqc_PID=$!

run_deseq2 & RUN_deseq2_PID=$!
wait -f $RUN_deseq2_PID
CODE=$?
if [[ "$CODE" != "0" ]] ; 
    then
        exit $CODE
fi

run_enrichments & RUN_enrichments_PID=$!
echo "- running rcistarget" && sleep 1
nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file params.json -entry rcistarget -profile ${PROFILE} >> ${LOGS}/rcistarget.log 2>&1 & RCISTARGET_PID=$!
echo "- running qc" && sleep 1
nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file params.json -entry qc -profile ${PROFILE} >> ${LOGS}/qc.log 2>&1 & QC_PID=$!
echo "- running cytoscape" && sleep 1
nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file params.json -entry string_cytoscape -profile ${PROFILE} >> ${LOGS}/string_cytoscape.log 2>&1 & CYTOSCAPE_PID=$!


for PID in $RUN_enrichments_PID $RCISTARGET_PID $QC_PID $CYTOSCAPE_PID ;
  do 
    wait -f $PID
    CODE=$?
    if [[ "$CODE" != "0" ]] ; 
        then
            exit $CODE
    fi
done

nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file params.json -entry upload -profile ${PROFILE} >> ${LOGS}/deseq2.log 2>&1 & DESEQ2_PID=$!

for PID in $RUN_featurecounts_and_multiqc_PID $DESEQ2_PID ; 
  do
    wait -f $PID
    CODE=$?
    if [[ "$CODE" != "0" ]] ; 
        then
            exit $CODE
    fi
done

cat $(find ../ -name upload.txt) > upload.txt
echo "main $(readlink -f ${LOGS}/software.txt)" >> upload.txt
echo "main $(readlink -f Material_and_Methods.md)" >> upload.txt
echo "- done" && sleep 1

exit
