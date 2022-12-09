# nextflow-rnaseq

Create the test directory:
```
mkdir -p ~/nextflow-rnaseq-test/raw_data
```

Download the demo data:
```
cd ~/nextflow-rnaseq-test/raw_data
curl -J -O https://datashare.mpcdf.mpg.de/s/jcEaS5vqpJO0lOy/download
curl -J -O https://datashare.mpcdf.mpg.de/s/XHanbnjfvQ9rACD/download
curl -J -O https://datashare.mpcdf.mpg.de/s/sIebkRdMfMSweq2/download
curl -J -O https://datashare.mpcdf.mpg.de/s/zoNxS9vRI7jl77y/download
curl -J -O https://datashare.mpcdf.mpg.de/s/0WHGNIhjJC792lY/download
curl -J -O https://datashare.mpcdf.mpg.de/s/ZlM0lWKPh8KrP6B/download
curl -J -O https://datashare.mpcdf.mpg.de/s/o3O6BKaEXqB7TTo/download
```

Download the paramaters file:
```
cd ~/nextflow-rnaseq-test
curl -J -O https://raw.githubusercontent.com/mpg-age-bioinformatics/nextflow-rnaseq/main/params.json
```

Run the workflow:
```
PROFILE=local

FASTQC_RELEASE=1.0.0
nextflow run mpg-age-bioinformatics/nf-fastqc -r ${FASTQC_RELEASE} -params-file params.json -entry images -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-fastqc -r ${FASTQC_RELEASE} -params-file params.json -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-fastqc -r ${FASTQC_RELEASE} -params-file params.json -entry upload -profile ${PROFILE}


KALLISTO_RELEASE=1.0.0
nextflow run mpg-age-bioinformatics/nf-kallisto -r ${KALLISTO_RELEASE} -params-file params.json -entry images -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-kallisto -r ${KALLISTO_RELEASE} -params-file params.json -entry get_genome -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-kallisto -r ${KALLISTO_RELEASE} -params-file params.json -entry write_cdna -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-kallisto -r ${KALLISTO_RELEASE} -params-file params.json -entry index -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-kallisto -r ${KALLISTO_RELEASE} -params-file params.json -entry check_strand -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-kallisto -r ${KALLISTO_RELEASE} -params-file params.json -entry map_reads -profile ${PROFILE} && \

FEATURECOUNTS_RELEASE=1.0.0
nextflow run mpg-age-bioinformatics/nf-featurecounts -r ${FEATURECOUNTS_RELEASE} -params-file params.json -entry images -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-featurecounts -r ${FEATURECOUNTS_RELEASE} -params-file params.json -profile ${PROFILE}

MULTIQC_RELEASE=1.0.0
nextflow run mpg-age-bioinformatics/nf-multiqc -r ${MULTIQC_RELEASE} -params-file params.json -entry images -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-multiqc -r ${MULTIQC_RELEASE} -params-file params.json -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-multiqc -r ${MULTIQC_RELEASE} -params-file params.json -entry upload -profile ${PROFILE}

DESEQ2_RELEASE=1.0.0
nextflow run mpg-age-bioinformatics/nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry images -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry preprocess -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry pairwise -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry annotate -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry david -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry topgo -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry cellplots -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry rcistarget -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry qc -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry string_cytoscape -profile ${PROFILE} && \
nextflow run mpg-age-bioinformatics/nf-deseq2 -r ${DESEQ2_RELEASE} -params-file params.json -entry upload -profile ${PROFILE}
```

