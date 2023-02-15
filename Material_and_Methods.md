# RNAseq

### Reference genomes and annotations

budding yeasts: Ensembl Candida albicans SC5314 release 22

caenorhabditis elegans: Ensembl Caenorhabditis elegans release 105 / ce11

homo sapiens: Ensembl Homo sapiens release 105/ hg38

drosophila melanogaster: Ensembl Drosophila melanogaster release 105 / BDGP6.32

mus musculus: Ensembl Mus musculus release 105 / mm39

nothobranchius furzeri: Ensembl Nothobranchius furzeri release 105 / Nfu_20140520

saccharomyces cerevisiae: Ensembl Saccharomyces cerevisiae release 105 / R64-1-1

### Removal or rRNA transcripts

rRNA transcripts were removed from the annotation file by depleting all lines with 'rrna' tag on it.

```
grep -v -i rrna <gtf> > <no.rRNA.gtf>
```

### ERCC spike ins

If ERCC option was selected ERCC92 reference sequences and annotations are added to the 
respective reference genome.

### Index building

cDNA fasta was generated using `gffread` (cufflinks/2.2.1):

```
gffread -w <cdna_fasta> -g <fasta> <no.rRNA.gtf>
```

cDNA index was build using kallisto (kallisto/0.46.1):

```
kallisto index -i <kallisto_index> <cdna_fasta>
```

### Determining strandness

4 million reads were pseudoaligned to reference transcriptome using kallisto/0.46.1:

```
# paired
kallisto quant -t 18 -i <kallisto_index> --genomebam -g <gtf> -c <chromosomes> -o <read_name> -b 100 <read_1> <read_2>

# single end
kallisto quant -t 18 -i <kallisto_index> --genomebam -g <gtf> -c <chromosomes> -o <read_name> -b 100 --single -l 200 -s 20 <read_1>
```

and RSeQC/4.0.0 used to indentify mapping strand:

```
infer_experiment.py -i <read_name>/pseudoalignments.bam -r <gene.model.bed> infer_experiment.txt
```

A strand was identified by having more than 60% of reads mapped to it. Cases with less than 60% of reads in
each strand are defined as unstranded.

### Alignment and quantification

Reads were pseudoaligned to reference transcriptome and quantified using kallisto/0.46.1:

```
# paired
kallisto quant -t 18 -i <kallisto_index> <--rf-stranded|--fr-stranded|unstranded> --genomebam -g <gtf> -c <chromosomes> -o <read_name> -b 100 <read_1> <read_2>

# single end
kallisto quant -t 18 -i <kallisto_index> <--rf-stranded|--fr-stranded|> --genomebam -g <gtf> -c <chromosomes> -o <read_name> -b 100 --single -l 200 -s 20 <read_1>
```

### Differential gene expression

After normalization of read counts by making use of the standard median-ratio for estimation of size factors, pair-wise differential gene expression was performed using DESeq2/1.24.0 

After removal of genes with less then 10 overall reads log2 fold changes were shrank using 
approximate posterior estimation for GLM coefficients.

## References:

*cufflinks* https://www.nature.com/articles/nprot.2012.016

*kallisto* https://www.nature.com/articles/nbt.3519

*RSeQC* https://academic.oup.com/bioinformatics/article/28/16/2184/325191

*DESeq2* https://genomebiology.biomedcentral.com/articles/10.1186/s13059-014-0550-8
