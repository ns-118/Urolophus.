#!/bin/bash --login

#---------------
#gfastats.sh : converts gfa to fasta format, and calculates assembly summary statistics

#---------------
#Requested resources:
#SBATCH --account=pawsey1348
#SBATCH --job-name=gfastats
#SBATCH --partition=work

#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --time=03:00:00
#SBATCH --mem=8G

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
sample=$(grep '^sample=' ../config.ini | cut -d '=' -f2)
seq_date="v$(grep '^seq_date=' ../config.ini | cut -d '=' -f2)"
gsize=$(grep '^gsize=' ../config.ini | cut -d '=' -f2)
asm_ver=$(grep '^asm_ver=' ../config.ini | cut -d '=' -f2)
ver="${seq_date}.${asm_ver}"


# Define paths
full_path=$(pwd)
fasta_dir="$(dirname "$full_path")/03-scaff"

echo "sample: $sample"
echo "seq_date: $seq_date"
echo "genome size: $gsize"
echo "ver: $ver"
echo "Full path: $full_path"
echo "Destination path for fastas: $fasta_dir"


#---------------
# Convert gfa to fasta

# Iterate over the files in the directory
for filename in "$full_path"/*ctg.gfa; do
    if [ -f "$filename" ]; then
        # Construct the output file path by replacing the extension with ".fasta"
        output_file="${filename%.*}.fasta"
        echo "Output file: $output_file"
        
        # Execute the gfastats command to convert GFA to FASTA
        singularity run $SING/gfastats:1.3.11.sif gfastats --discover-paths "$filename" -o fa > "$output_file"
        echo "Converted $filename to $output_file"

        # Move the fasta files to the destination directory
        mv "$output_file" "$fasta_dir/"
        echo "Fasta file moved to $fasta_dir/"
    fi
done


#---------------
# Calculate summary statistics

# Iterate over the files in the directory
for filename in "$full_path"/*ctg.gfa; do
    # Construct the output file path by replacing the extension with ".assembly.summary.txt"
    output_file="${filename%.*}.assembly.summary.txt"

    # Execute the gfastats command to calculate assembly statistics
    singularity run $SING/gfastats:1.3.11.sif gfastats "$filename" $gsize --discover-paths --tabular --nstar-report > "$output_file"

    # Check if the gfastats command was successful
    if [ $? -eq 0 ]; then
        echo "Calculated assembly statistics for $filename and saved results to $output_file"
        # Move the statistics file to the 'qc/gfastats' directory
        mv "$output_file" qc/gfastats/
        echo "Statistics file moved to the 'qc/gfastats' directory"
    else
        echo "Failed to calculate assembly statistics for $filename"
    fi
done

#---------------
# copy data to Acacia s3 storage
echo "Backing up gfastats results... "
cp "qc/gfastats/${sample}_${seq_date}.hic.p_ctg.assembly.summary.txt" "${sample}_${ver}.0.hifiasm.p_ctg.assembly.summary.txt"
cp "qc/gfastats/${sample}_${seq_date}.hic.a_ctg.assembly.summary.txt" "${sample}_${ver}.0.hifiasm.a_ctg.assembly.summary.txt"
cp "qc/gfastats/${sample}_${seq_date}.hic.hap1.p_ctg.assembly.summary.txt" "${sample}_${ver}.0.hifiasm.hap1.p_ctg.assembly.summary.txt"
cp "qc/gfastats/${sample}_${seq_date}.hic.hap2.p_ctg.assembly.summary.txt" "${sample}_${ver}.0.hifiasm.hap2.p_ctg.assembly.summary.txt"

rclone move "${sample}_${ver}.0.hifiasm.p_ctg.assembly.summary.txt" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/gfastats
rclone move "${sample}_${ver}.0.hifiasm.a_ctg.assembly.summary.txt" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/gfastats
rclone move "${sample}_${ver}.0.hifiasm.hap1.p_ctg.assembly.summary.txt" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/gfastats
rclone move "${sample}_${ver}.0.hifiasm.hap2.p_ctg.assembly.summary.txt" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/gfastats

echo "Backing up fasta files... "
cp "${fasta_dir}/${sample}_${seq_date}.hic.p_ctg.fasta" "${sample}_${ver}.0.hifiasm.p_ctg.fasta"
cp "${fasta_dir}/${sample}_${seq_date}.hic.a_ctg.fasta" "${sample}_${ver}.0.hifiasm.a_ctg.fasta"
cp "${fasta_dir}/${sample}_${seq_date}.hic.hap1.p_ctg.fasta" "${sample}_${ver}.0.hifiasm.hap1.p_ctg.fasta"
cp "${fasta_dir}/${sample}_${seq_date}.hic.hap2.p_ctg.fasta" "${sample}_${ver}.0.hifiasm.hap2.p_ctg.fasta"

rclone move "${sample}_${ver}.0.hifiasm.p_ctg.fasta" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/assembly
rclone move "${sample}_${ver}.0.hifiasm.a_ctg.fasta" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/assembly
rclone move "${sample}_${ver}.0.hifiasm.hap1.p_ctg.fasta" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/assembly
rclone move "${sample}_${ver}.0.hifiasm.hap2.p_ctg.fasta" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/assembly

echo "Backing up gfa files... "
cp "${sample}_${seq_date}.hic.p_ctg.gfa" "${sample}_${ver}.0.hifiasm.p_ctg.gfa"
cp "${sample}_${seq_date}.hic.a_ctg.gfa" "${sample}_${ver}.0.hifiasm.a_ctg.gfa"
cp "${sample}_${seq_date}.hic.hap1.p_ctg.gfa" "${sample}_${ver}.0.hifiasm.hap1.p_ctg.gfa"
cp "${sample}_${seq_date}.hic.hap2.p_ctg.gfa" "${sample}_${ver}.0.hifiasm.hap2.p_ctg.gfa"

rclone move "${sample}_${ver}.0.hifiasm.p_ctg.gfa" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/assembly
rclone move "${sample}_${ver}.0.hifiasm.a_ctg.gfa" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/assembly
rclone move "${sample}_${ver}.0.hifiasm.hap1.p_ctg.gfa" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/assembly
rclone move "${sample}_${ver}.0.hifiasm.hap2.p_ctg.gfa" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/assembly


#---------------
#Successfully finished
echo "Done"
exit 0
