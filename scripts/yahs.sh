#!/bin/bash --login

#SBATCH --account=pawsey1348
#SBATCH --job-name=yahs
#SBATCH --partition=highmem
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=nicholas.stratmann@utas.edu.au
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=48
#SBATCH --time=24:00:00
#SBATCH --mem=900G
#SBATCH --export=ALL
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -euo pipefail
date=$(date +%y%m%d)

echo "========================================="
echo "SLURM_JOB_ID = $SLURM_JOB_ID"
echo "SLURM_NODELIST = $SLURM_NODELIST"
echo "DATE: $date"
echo "========================================="

#---------------
# Load the singularity module
module load singularity/3.11.4-nompi
SING="/software/projects/pawsey1348/singularity/"
#---------------
# Define variables
full_path=$(pwd)
echo "Full path: $full_path"

# Define the assembly file 
assembly_file="$1"
echo "assembly file: $assembly_file"

# Define the bam file - Hi-C reads mapped to contigs   
bam="$2"
echo "bam file: $bam"

# Define output prefix
output_file=$(echo "$assembly_file" | sed -r 's/\.0\.hifiasm\./.1.yahs./; s/\.p_ctg\.fasta$//')
echo "Output file: $output_file"

# Destination path for fasta files
fasta_dir="$(dirname "$full_path")/04-decontam"
echo "Destination path for fastas: $fasta_dir"

# --------------
# Run yahs
module load pawseyenv/2024.05
module load samtools/1.15--h3843a85_0
samtools faidx "$assembly_file"

# Enable core dumps for postmortem debugging
ulimit -c unlimited || true
echo "Core dump limit: $(ulimit -c 2>/dev/null || echo unknown)"

# Build singularity command depending on debug/strace flags:
# - SING_DEBUG=1 : run singularity with --debug and capture verbose log
# - STRACE_BIND=1: bind-mount host /usr/bin/strace into container and run strace inside
# - STRACE=1     : attempt to run strace inside container (may fail if not present)
singularity_cmd=""
if [[ "${SING_DEBUG:-0}" == "1" ]]; then
  singularity_cmd="singularity --debug exec \"$SING/yahs.1.2.2.new.sif\""
else
  singularity_cmd="singularity exec \"$SING/yahs.1.2.2.new.sif\""
fi

if [[ "${STRACE_BIND:-0}" == "1" ]]; then
  echo "Running yahs inside container with host strace bind-mounted (output: ${output_file}.strace)"
  # Bind host /usr/bin/strace into container and invoke strace inside
  singularity_cmd="singularity exec -B /usr/bin/strace:/usr/bin/strace \"$SING/yahs.1.2.2.new.sif\" strace -ff -o \"${output_file}.strace\" /usr/local/bin/yahs --no-contig-ec -o \"$output_file\" \"$assembly_file\" \"$bam\""
elif [[ "${STRACE:-0}" == "1" ]]; then
  echo "Running yahs under strace inside container (output: ${output_file}.strace)"
  singularity_cmd="singularity exec \"$SING/yahs.1.2.2.new.sif\" strace -ff -o \"${output_file}.strace\" /usr/local/bin/yahs --no-contig-ec -o \"$output_file\" \"$assembly_file\" \"$bam\""
else
  singularity_cmd="singularity exec \"$SING/yahs.1.2.2.new.sif\" /usr/local/bin/yahs --no-contig-ec -o \"$output_file\" \"$assembly_file\" \"$bam\""
fi

echo "Singularity command: $singularity_cmd"

# Run the command and capture exit code for debugging (temporarily disable errexit)
set +e
eval $singularity_cmd
sing_exit_code=$?
set -e
echo "Singularity exit code: $sing_exit_code"

# Dump any core or strace files to help debugging
echo "Listing potential core/strace files in working directory:" 
ls -lh core* "${output_file}.strace"* 2>/dev/null || true

if [[ $sing_exit_code -ne 0 ]]; then
  echo "ERROR: singularity command failed with exit code $sing_exit_code"
  # continue to allow the rest of the script to perform its checks (file move will fail if output missing)
fi

echo "yahs finished successfully"

scaffold_fa="${output_file}_scaffolds_final.fa"
if [[ -f "$scaffold_fa" ]]; then
  mkdir -p "$fasta_dir"
  mv "$scaffold_fa" "$fasta_dir/"
  echo "Fasta file moved to $fasta_dir/"
else
  echo "ERROR: expected output file '$scaffold_fa' not found"
  exit 1
fi

# --------------
# Cleanup: Delete unwanted files
find . -type f -name "${output_file}*.agp" ! -name "${output_file}_final.agp" -exec rm {} \;
find . -type f -name "${output_file}*.bin" -exec rm {} \;

#---------------
# Successfully finished
echo "Done"
exit 0
