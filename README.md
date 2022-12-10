# nextflow-rnaseq

Prerequisites:

- nextflow: [https://www.nextflow.io](https://www.nextflow.io)
- docker: [https://www.docker.com](https://www.docker.com)
- unix based system

Create the project and raw data folder:
```bash
mkdir -p ~/nextflow-rnaseq-run/raw_data
```

Copy the data to your raw data folder (eg. demo data):
```bash
cd ~/nextflow-rnaseq-run/raw_data
curl -J -O https://datashare.mpcdf.mpg.de/s/jcEaS5vqpJO0lOy/download
curl -J -O https://datashare.mpcdf.mpg.de/s/XHanbnjfvQ9rACD/download
curl -J -O https://datashare.mpcdf.mpg.de/s/sIebkRdMfMSweq2/download
curl -J -O https://datashare.mpcdf.mpg.de/s/zoNxS9vRI7jl77y/download
curl -J -O https://datashare.mpcdf.mpg.de/s/0WHGNIhjJC792lY/download
curl -J -O https://datashare.mpcdf.mpg.de/s/ZlM0lWKPh8KrP6B/download
curl -J -O https://datashare.mpcdf.mpg.de/s/o3O6BKaEXqB7TTo/download
```

Add the run script, paramaters file, and sample sheet to the project folder:
```bash
cd ~/nextflow-rnaseq-run
curl -J -O https://raw.githubusercontent.com/mpg-age-bioinformatics/nextflow-rnaseq/main/nextflow-rnaseq.local.sh
curl -J -O https://raw.githubusercontent.com/mpg-age-bioinformatics/nextflow-rnaseq/main/params.local.json
curl -J -O https://raw.githubusercontent.com/mpg-age-bioinformatics/nf-deseq2/main/sample_sheet.xlsx
```

If you have a sample sheet and parameters file generated by Flaski use them instead of the `json` and `xlsx` above.

Edit the contents of `params.local.json` replacing the `~` with the full path to your home folder. Eg.
```bash
# linux
sed -i 's/\~/\/Users\/jboucas/g' params.local.json
# mac 
sed -i '' 's/\~/\/Users\/jboucas/g' params.local.json
```

Run the workflow:
```bash
cd ~/nextflow-rnaseq-run
bash nextflow-rnaseq.local.sh release params.local.json
```

Most relevant results files will be found in `~/nextflow-rnaseq-run/summary` eg.:
```
./multiqc
./multiqc/multiqc_report.html
./deseq2
./deseq2/masterTable_annotated.xlsx
./deseq2/group_muscle_vs_intestine.results.xlsx
./deseq2/significant.xlsx
./togo
./togo/group_muscle_vs_intestine.topGO.tsv
./togo/group_muscle_vs_intestine.topGO.GOTERM_BP.cellplot.pdf
./togo/group_muscle_vs_intestine.topGO.GOTERM_BP.symplot.pdf
./togo/group_muscle_vs_intestine.topGO.xlsx
./qc_plots
./qc_plots/count.matrix.scatter.plot.pdf
./qc_plots/p.value.dist.pdf
./qc_plots/pca_all_samples.pdf
./qc_plots/grouped.KDE.pdf
./qc_plots/sigFeatures.matrix.pdf
./qc_plots/sample.distance.matrix.pdf
./qc_plots/MA.plots.pdf
./qc_plots/sample.KDE.pdf
./qc_plots/grouped.barPlots.pdf
./qc_plots/q.value.dist.pdf
./qc_plots/sample.dendrogram.pdf
./qc_plots/pca_comp_all_samples.xlsx
./qc_plots/sample.barPlots.pdf
./qc_plots/group_muscle_vs_intestine_pca.xlsx
./qc_plots/pca.pdf
./qc_plots/volcano.plots.pdf
./qc_plots/grouped.heatMap.pdf
./qc_plots/sample.heatMap.pdf
./qc_plots/group.distance.matrix.pdf
```