#!/bin/bash --login

#---------------
#meryl.sh : runs meryl for generating k-mer spectra from unassembled sequencing data

#---------------
#Requested resources:
#SBATCH --account=pawsey1348
#SBATCH --job-name=meryl
#SBATCH --partition=work

#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=128 
#SBATCH --time=3:00:00
#SBATCH --mem=160G

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
tolid=$(grep '^tolid=' ../../config.ini | cut -d '=' -f2)
seq_date="v$(grep '^seq_date=' ../../config.ini | cut -d '=' -f2)"

# Define paths
full_path=$(pwd)
processed_dir="$(dirname "$(dirname "$full_path")")/01-kmer-profiling"

# Define output prefix
out="${sample}.meryl"

echo "sample: $sample"
echo "ToLID: $tolid"
echo "seq_date: $seq_date"
echo "Full path: $full_path"
echo "Target directory: $processed_dir"
echo "Output prefix: $out"


#---------------
# Create meryl database, then extract meryl histogram
singularity run $SING/meryl:1.3.sif meryl k=31 memory=160 count *.fastq.gz output $out \
&& singularity run $SING/meryl:1.3.sif meryl histogram $out > "$sample.meryl.hist" \
&& (
    find . -type d -name "*.meryl" -exec mv {} "$processed_dir" \;
    find . -type f -name "*.meryl.hist" -exec mv {} "$processed_dir" \;
    )
echo "Extracted meryl histogram and moved output files to the target directory."

#---------------
# copy data to Acacia s3 storage
#echo "Backing up meryl database... "
#tar -czvf "${processed_dir}/${tolid}_${seq_date}_meryldb.tar.gz" "${processed_dir}/${sample}.meryl" && rclone copy "${processed_dir}/${tolid}_${seq_date}_meryldb.tar.gz" pawsey0812:oceanomics-assemblies/${sample}/meryl
#rclone copy "${processed_dir}/${sample}.meryl.hist" pawsey0812:oceanomics-assemblies/${sample}/meryl


#---------------
#Successfully finished
echo "Done"
exit 0
