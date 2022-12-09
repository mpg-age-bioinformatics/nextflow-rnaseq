#!/bin/bash

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

 wait_and_echo() {
    PID=$1
    echo Waiting for PID $PID to terminate
    wait $PID
    CODE=$?
    echo PID $PID terminated with exit code $CODE
    return $CODE
}

PROFILE=$1

if [[ "$2" != "clone" ]] ; 
  then

    ORIGIN="mpg-age-bioinformatics/"

    FASTQC_RELEASE="-r $(get_latest_release ${ORIGIN}nf-fastqc)"
    KALLISTO_RELEASE="-r $(get_latest_release ${ORIGIN}nf-kallisto)"
    FEATURECOUNTS_RELEASE="-r $(get_latest_release ${ORIGIN}nf-featurecounts)"
    MULTIQC_RELEASE="-r $(get_latest_release ${ORIGIN}nf-multiqc)"
    DESEQ2_RELEASE="-r $(get_latest_release ${ORIGIN}nf-deseq2)"

else

  for repo in nf-deseq2 nf-kallisto nf-featurecounts nf-multiqc nf-deseq2 ; 
    do

      if [[ ! -e ${repo} ]] ;
        then
          git clone git@github.com:mpg-age-bioinformatics/${repo}.git
      fi

  done

fi


get_images() {
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file params.json -entry images -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-kallisto ${KALLISTO_RELEASE} -params-file params.json -entry images -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-featurecounts ${FEATURECOUNTS_RELEASE} -params-file params.json -entry images -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-multiqc ${MULTIQC_RELEASE} -params-file params.json -entry images -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-deseq2 ${DESEQ2_RELEASE} -params-file params.json -entry images -profile ${PROFILE}
}

run_fastqc() {
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file params.json -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file params.json -entry upload -profile ${PROFILE}
}

run_kallisto() {
  nextflow run ${ORIGIN}nf-kallisto -r ${KALLISTO_RELEASE} -params-file params.json -entry get_genome -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-kallisto -r ${KALLISTO_RELEASE} -params-file params.json -entry write_cdna -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-kallisto -r ${KALLISTO_RELEASE} -params-file params.json -entry index -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-kallisto -r ${KALLISTO_RELEASE} -params-file params.json -entry check_strand -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-kallisto -r ${KALLISTO_RELEASE} -params-file params.json -entry map_reads -profile ${PROFILE}
}

run_featurecounts_and_multiqc() {
  nextflow run ${ORIGIN}nf-featurecounts -r ${FEATURECOUNTS_RELEASE} -params-file params.json -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-multiqc -r ${MULTIQC_RELEASE} -params-file params.json -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-multiqc -r ${MULTIQC_RELEASE} -params-file params.json -entry upload -profile ${PROFILE}
}

run_deseq2() {
  nextflow run ${ORIGIN}nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry preprocess -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry pairwise -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry annotate -profile ${PROFILE}
}

run_enrichments() {
  nextflow run ${ORIGIN}nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry david -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry topgo -profile ${PROFILE} && \
  nextflow run ${ORIGIN}nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry cellplots -profile ${PROFILE}
}

get_images && \
run_fastqc & RUN_fastqc_PID=$!
run_kallisto & RUN_kallisto_PID=$!
wait_and_echo $RUN_fastqc_PID && \
run_featurecounts_and_multiqc & RUN_featurecounts_and_multiqc_PID=$!
run_deseq2 && \
run_enrichments & RUN_enrichments_PID=$!
nextflow run ${ORIGIN}nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry rcistarget -profile ${PROFILE} & RCISTARGET_PID=$!
nextflow run ${ORIGIN}nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry qc -profile ${PROFILE} & QC_PID=$!
nextflow run ${ORIGIN}nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry string_cytoscape -profile ${PROFILE} & CYTOSCAPE_PID=$!

for p in $RUN_enrichments_PID $RCISTARGET_PID $QC_PID $CYTOSCAPE_PID ;
  do 
    wait_and_echo $p
done
nextflow run ${ORIGIN}nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry upload -profile ${PROFILE} $ DESEQ2_PID=$!

for p in $RUN_fastqc_PID $DESEQ2_PID ; 
  do
    wait_and_echo $p
done

echo "Done"
