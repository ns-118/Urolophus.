#!/bin/bash --login

#---------------
#hifiasm.sh: runs HiFiasm - a fast haplotype-resolved de novo assembler for PacBio HiFi reads, with Hi-C integration

#---------------
#Requested resources:
#SBATCH --account=pawsey1348
#SBATCH --job-name=hifiasm
#SBATCH --partition=highmem

#SBATCH --ntasks=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --time=48:00:00
#SBATCH --mem=900G

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
seq_date="v$(grep '^seq_date=' ../../config.ini | cut -d '=' -f2)"
asm_ver=$(grep '^asm_ver=' ../../config.ini | cut -d '=' -f2)
ver="${seq_date}.${asm_ver}"
out="${sample}_${seq_date}"

# Define paths
full_path=$(pwd)
processed_dir="$(dirname "$(dirname "$full_path")")/02-assembly"
hic_dir="$(dirname "$full_path")/raw/hic/"

echo "sample: $sample"
echo "seq_date: $seq_date"
echo "ver: $ver"
echo "output prefix: $out"
echo "Full path: $full_path"
echo "Target directory: $processed_dir"


# Define Hi-C files 
H1="${hic_dir}"*R1*.fastq.gz
for file in $H1; do
    echo "Hi-C forward: $file"
done

H2="${hic_dir}"*R2*.fastq.gz
for file in $H2; do
    echo "Hi-C reverse: $file"
done


#---------------
# Run hifiasm, then move output files to target dir
singularity run $SING/hifiasm:0.25.0.sif hifiasm -t 128 -o $out --primary --h1 ${H1} --h2 ${H2} *fastq.gz \
&& find . -type f \( -name "*.gfa" -o -name "*.bed" -o -name "*.bin" \) -exec mv {} "$processed_dir" \;
echo "Assembly output files moved to the 02-assembly directory."

#---------------
#Successfully finished
echo "Done"
exit 0
