#!/bin/bash --login

#---------------
#busco.sh.sh : assesses the completeness of an assembled genome using known highly conserved genes

#---------------
#Requested resources:
#SBATCH --account=pawsey1348
#SBATCH --job-name=busco
#SBATCH --partition=work

#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --time=05:00:00
#SBATCH --mem=128G

#SBATCH --export=ALL
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

date=$(date +%y%m%d)

echo "========================================="
echo "SLURM_JOB_ID = $SLURM_JOB_ID"
echo "SLURM_NODELIST = $SLURM_NODELIST"
echo "DATE: $date"
echo "========================================="


#---------------
# Load the singularity module
module load singularity/3.11.4-nompi

#---------------
# Define variables from config file
sample=$(grep '^sample=' ../../config.ini | cut -d '=' -f2)
busco_db=$(grep '^busco_db=' ../../config.ini | cut -d '=' -f2)
seq_date="v$(grep '^seq_date=' ../../config.ini | cut -d '=' -f2)"
asm_ver=$(grep '^asm_ver=' ../../config.ini | cut -d '=' -f2)
ver="${seq_date}.${asm_ver}"

# Define paths
full_path=$(pwd)
asm_path="$(dirname "$(dirname "$full_path")")/03-scaff"

echo "sample: $sample"
echo "seq_date: $seq_date"
echo "ver: $ver"
echo "Full path: $full_path"
echo "Path to assemblies: $asm_path"
echo "BUSCO database: $busco_db"

# define prefix to trim from file names
prefix="${sample}_${seq_date}"
echo "Prefix: $prefix"


# define function to rename files
rename_files() {
    for file in "$1"/*${prefix}*.hic*; do
        # Extract the base filename without the path
        base_filename=$(basename "$file")
        # Construct the new filename
        new_filename="busco_out/${base_filename/${prefix}\.hic./}"
        new_filename="${new_filename/.hic./.}"
        # Rename the file
        mv "$file" "$new_filename"
    done
}


#---------------
# Run BUSCO
singularity run -B /software/projects/pawsey1348 $SING/busco:5.6.1.sif busco --in $asm_path -m genome -l "/software/projects/pawsey1348/${busco_db}" --cpu 128 --miniprot --out busco_out && \
find busco_out -name "short_summary.specific*" -type f -exec mv {} busco_out \; && \
rename_files busco_out && \
singularity run -B /software/projects/pawsey1348 -B $SING/busco:5.6.1.sif generate_plot.py -wd busco_out -rt specific && \
find busco_out -type f ! \( -name 'full_table.tsv' -o -name 'missing_busco_list.tsv' -o -name 'busco_figure.png' -o -name '*summary*' \) -exec rm {} + && \
rm -r busco_downloads && \
find busco_out -depth -type d -empty -exec rmdir {} \;


#---------------
# copy data to Acacia s3 storage
echo "Backing up QC on assembled contigs... "

cp "busco_out/busco_figure.png" "${sample}_${ver}.0.hifiasm.busco_figure.png"
cp "busco_out/batch_summary.txt" "${sample}_${ver}.0.hifiasm.batch_summary.txt"

rclone move "${sample}_${ver}.0.hifiasm.busco_figure.png" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco
rclone move "${sample}_${ver}.0.hifiasm.batch_summary.txt" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco

# hap1
cp "busco_out/short_summary.specific.${busco_db}.hap1.p_ctg.fasta.txt" "${sample}_${ver}.0.hifiasm.hap1_short_summary.specific.${busco_db}.txt"
cp "busco_out/short_summary.specific.${busco_db}.hap1.p_ctg.fasta.json" "${sample}_${ver}.0.hifiasm.hap1_short_summary.specific.${busco_db}.json"
cp "busco_out/hap1.p_ctg.fasta/run_${busco_db}/full_table.tsv" "${sample}_${ver}.0.hifiasm.hap1_full_table.tsv"
cp "busco_out/hap1.p_ctg.fasta/run_${busco_db}/missing_busco_list.tsv" "${sample}_${ver}.0.hifiasm.hap1_missing_busco_list.tsv"

rclone move "${sample}_${ver}.0.hifiasm.hap1_short_summary.specific.${busco_db}.txt" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco
rclone move "${sample}_${ver}.0.hifiasm.hap1_short_summary.specific.${busco_db}.json" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco
rclone move "${sample}_${ver}.0.hifiasm.hap1_full_table.tsv" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco
rclone move "${sample}_${ver}.0.hifiasm.hap1_missing_busco_list.tsv" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco

# hap2
cp "busco_out/short_summary.specific.${busco_db}.hap2.p_ctg.fasta.txt" "${sample}_${ver}.0.hifiasm.hap2_short_summary.specific.${busco_db}.txt"
cp "busco_out/short_summary.specific.${busco_db}.hap2.p_ctg.fasta.json" "${sample}_${ver}.0.hifiasm.hap2_short_summary.specific.${busco_db}.json"
cp "busco_out/hap2.p_ctg.fasta/run_${busco_db}/full_table.tsv" "${sample}_${ver}.0.hifiasm.hap2_full_table.tsv"
cp "busco_out/hap2.p_ctg.fasta/run_${busco_db}/missing_busco_list.tsv" "${sample}_${ver}.0.hifiasm.hap2_missing_busco_list.tsv"

rclone move "${sample}_${ver}.0.hifiasm.hap2_short_summary.specific.${busco_db}.txt" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco
rclone move "${sample}_${ver}.0.hifiasm.hap2_short_summary.specific.${busco_db}.json" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco
rclone move "${sample}_${ver}.0.hifiasm.hap2_full_table.tsv" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco
rclone move "${sample}_${ver}.0.hifiasm.hap2_missing_busco_list.tsv" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco

# primary
cp "busco_out/short_summary.specific.${busco_db}.p_ctg.fasta.txt" "${sample}_${ver}.0.hifiasm.pri_short_summary.specific.${busco_db}.txt"
cp "busco_out/short_summary.specific.${busco_db}.p_ctg.fasta.json" "${sample}_${ver}.0.hifiasm.pri_short_summary.specific.${busco_db}.json"
cp "busco_out/p_ctg.fasta/run_${busco_db}/full_table.tsv" "${sample}_${ver}.0.hifiasm.pri_full_table.tsv"
cp "busco_out/p_ctg.fasta/run_${busco_db}/missing_busco_list.tsv" "${sample}_${ver}.0.hifiasm.pri_missing_busco_list.tsv"

rclone move "${sample}_${ver}.0.hifiasm.pri_short_summary.specific.${busco_db}.txt" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco
rclone move "${sample}_${ver}.0.hifiasm.pri_short_summary.specific.${busco_db}.json" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco
rclone move "${sample}_${ver}.0.hifiasm.pri_full_table.tsv" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco
rclone move "${sample}_${ver}.0.hifiasm.pri_missing_busco_list.tsv" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco

# alternate
cp "busco_out/short_summary.specific.${busco_db}.a_ctg.fasta.txt" "${sample}_${ver}.0.hifiasm.alt_short_summary.specific.${busco_db}.txt"
cp "busco_out/short_summary.specific.${busco_db}.a_ctg.fasta.json" "${sample}_${ver}.0.hifiasm.alt_short_summary.specific.${busco_db}.json"
cp "busco_out/a_ctg.fasta/run_${busco_db}/full_table.tsv" "${sample}_${ver}.0.hifiasm.alt_full_table.tsv"
cp "busco_out/a_ctg.fasta/run_${busco_db}/missing_busco_list.tsv" "${sample}_${ver}.0.hifiasm.alt_missing_busco_list.tsv"

rclone move "${sample}_${ver}.0.hifiasm.alt_short_summary.specific.${busco_db}.txt" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco
rclone move "${sample}_${ver}.0.hifiasm.alt_short_summary.specific.${busco_db}.json" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco
rclone move "${sample}_${ver}.0.hifiasm.alt_full_table.tsv" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco
rclone move "${sample}_${ver}.0.hifiasm.alt_missing_busco_list.tsv" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco


#---------------
# Successfully finished
echo "Done"
exit 0
