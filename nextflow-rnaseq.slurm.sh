#!/bin/bash

source RNAseq.config

## usage:
## $1 : `release` for latest nextflow/git release; `checkout` for git clone followed by git checkout of a tag ; `clone` for latest repo commit
## $2 : profile

set -e


module load singularity


wait_for(){
    PID=$(echo "$1" | cut -d ":" -f 1 )
    PRO=$(echo "$1" | cut -d ":" -f 2 )
    echo "$(date '+%Y-%m-%d %H:%M:%S'): waiting for ${PRO}"
    wait $PID
    CODE=$?
    
    if [[ "$CODE" != "0" ]] ; 
        then
            echo "$PRO failed"
            echo "$CODE"
            failed=true
            #exit $CODE
    fi
}


get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

PROFILE=$2
LOGS="work"
PARAMS="params.json"

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

  for repo in nf-fastqc nf-deseq2 nf-kallisto nf-featurecounts nf-multiqc nf-deseq2 ; 
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
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -w ${LOGS}/.fastqc -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1 && \
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -w ${LOGS}/.fastqc_upload -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1
}

run_kallisto() {
  echo "- running kallisto"
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -w ${LOGS}/.kallisto_get_genome -params-file ${PARAMS} -entry get_genome -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -w ${LOGS}/.kallisto_write_cdna -params-file ${PARAMS} -entry write_cdna -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -w ${LOGS}/.kallisto_index -params-file ${PARAMS} -entry index -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -w ${LOGS}/.kallisto_check_strand -params-file ${PARAMS} -entry check_strand -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1 && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -w ${LOGS}/.kallisto_map_reads -params-file ${PARAMS} -entry map_reads -profile ${PROFILE} >> ${LOGS}/kallisto.log 2>&1
}

run_featurecounts_and_multiqc() {
  echo "- running featurecounts" && \
  nextflow run ${ORIGIN}nf-featurecounts ${FEATURECOUNTS_RELEASE} -w ${LOGS}/.featurecounts -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/featurecounts.log 2>&1 && \
  echo "- running multiqc" && \
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -w ${LOGS}/.multiqc -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/multiqc.log 2>&1 && \
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -w ${LOGS}/.multiqc_upload -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/multiqc.log 2>&1
}

run_deseq2() {
  echo "- running deseq2" && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -w ${LOGS}/.deseq2_preprocess -params-file ${PARAMS} -entry preprocess -profile ${PROFILE} >> ${LOGS}/deseq2.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -w ${LOGS}/.deseq2_pairwise -params-file ${PARAMS} -entry pairwise -profile ${PROFILE} >> ${LOGS}/deseq2.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -w ${LOGS}/.deseq2_annotate -params-file ${PARAMS} -entry annotate -profile ${PROFILE} >> ${LOGS}/deseq2.log 2>&1
}

run_enrichments() {
  echo "- running enrichments"
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} --DAVIDUSER ${DAVIDUSER} -w ${LOGS}/.deseq2-david -params-file ${PARAMS} -entry david -profile ${PROFILE} >> ${LOGS}/enrichments.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -w ${LOGS}/.deseq2_topgo -params-file ${PARAMS} -entry topgo -profile ${PROFILE} >> ${LOGS}/enrichments.log 2>&1 && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -w ${LOGS}/.deseq2_cellplots -params-file ${PARAMS} -entry cellplots -profile ${PROFILE} >> ${LOGS}/enrichments.log 2>&1
}

get_images && sleep 1
run_fastqc & RUN_fastqc_PID=$!
sleep 1
run_kallisto & RUN_kallisto_PID=$!
sleep 1

for PID in "${RUN_fastqc_PID}:FASTQC" "${RUN_kallisto_PID}:KALLISTO" ; 
    do
        wait_for $PID
        # wait $PID
        # CODE=$?
        # if [[ "$CODE" != "0" ]] ; 
        #     then
        #         echo "exit $CODE"
        #         exit $CODE
        # fi     
done

run_featurecounts_and_multiqc & RUN_featurecounts_and_multiqc_PID=$!

run_deseq2 && sleep 1
# wait $RUN_deseq2_PID
# CODE=$?
# if [[ "$CODE" != "0" ]] ; 
#     then
#         echo "exit $CODE"
#         exit $CODE
# fi

run_enrichments & RUN_enrichments_PID=$!
echo "- running rcistarget" && sleep 1
nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry rcistarget -profile ${PROFILE} >> ${LOGS}/rcistarget.log 2>&1 & RCISTARGET_PID=$!
echo "- running qc" && sleep 1
nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry qc -profile ${PROFILE} >> ${LOGS}/qc.log 2>&1 & QC_PID=$!
echo "- running cytoscape" && sleep 1
nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry string_cytoscape -profile ${PROFILE} >> ${LOGS}/string_cytoscape.log 2>&1 & CYTOSCAPE_PID=$!


for PID in "${RUN_enrichments_PID}:enrichments" "${RCISTARGET_PID}:rcistarget" "${QC_PID}:qc" "${CYTOSCAPE_PID}:cytoscape" ;
  do 
    wait_for $PID
    # wait $PID
    # CODE=$?
    # if [[ "$CODE" != "0" ]] ; 
    #     then
    #         echo "exit $CODE"
    #         exit $CODE
    # fi
done

nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/deseq2.log 2>&1 & DESEQ2_PID=$!

for PID in "${RUN_featurecounts_and_multiqc_PID}:featurecounts_and_multiqc" "${DESEQ2_PID}:deseq2_upload" ; 
  do
    wait_for $PID
    # wait $PID
    # CODE=$?
    # if [[ "$CODE" != "0" ]] ; 
    #     then
    #         echo "exit $CODE"
    #         exit $CODE
    # fi
done

rm -rf ${project_folder}/upload.txt
cat $(find ${project_folder}/ -name upload.txt) > ${project_folder}/upload.txt
sort -u ${LOGS}/software.txt > ${LOGS}/software.txt_
mv ${LOGS}/software.txt_ ${LOGS}/software.txt
cp ${LOGS}/software.txt ${project_folder}/software.txt
cp Material_and_Methods.md ${project_folder}/Material_and_Methods.md
echo "main $(readlink -f ${project_folder}/software.txt)" >> ${project_folder}/upload.txt
echo "main $(readlink -f ${project_folder}/Material_and_Methods.md)" >> ${project_folder}/upload.txt
cp ${project_folder}/upload.txt ${upload_list}
echo "- done" && sleep 1

exit
