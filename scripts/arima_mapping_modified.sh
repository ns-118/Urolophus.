#!/bin/bash --login

##############################################
# ARIMA GENOMICS MAPPING PIPELINE 07/26/2023 #
##############################################

# Below find the commands used to map HiC data.

# Replace the variables at the top with the correct paths for the locations of files/programs on your system.

#SBATCH --account=pawsey1348
#SBATCH --job-name=arima_mapping_
#SBATCH --partition=highmem
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=nicholas.stratmann@utas.edu.au
#SBATCH --qos=high

#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --time=96:00:00
#SBATCH --mem=900G

#SBATCH --export=ALL
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -o pipefail

##########################################
# Commands #
##########################################

PAIRTOOLS="/software/projects/pawsey1348/singularity/pairtools.sif"
BWA="/software/projects/pawsey1348/singularity/bwa_0.7.17--h7132678_9.sif"
FASTP="/software/projects/pawsey1348/singularity/fastp.sif"

export PATH="/software/setonix/2025.08/software/linux-sles15-zen3/gcc-14.2.0/singularityce-4.1.0-oywepmdbs2cm4lhqsz5ipg5gjty6ddc4/bin:$PATH"

full_path=$(pwd)
echo "Full path: $full_path"

if [[ $full_path =~ /([^/]+)/03-scaff ]]; then
    sample=${BASH_REMATCH[1]}
    echo "Sample: $sample"
else
    echo "ERROR: Could not extract sample name from path: $full_path"
    echo "Expected path to contain /<sample>/03-scaff"
    exit 1
fi

hic_dir="$(dirname "$full_path")/data/raw/hic/"

H1=$(find "$hic_dir" -name "*R1*.fastq.gz" | head -1)
H2=$(find "$hic_dir" -name "*R2*.fastq.gz" | head -1)

assembly_file="$1"
output_file="${assembly_file%.p_ctg.fasta}"
export TMPDIR=/scratch/pawsey1348/nstratmann/tmp

##########################################
# Pre-flight checks #
##########################################
errors=0

if [ ! -f "$PAIRTOOLS" ]; then
    echo "ERROR: Pairtools container not found: $PAIRTOOLS"
    errors=$((errors + 1))
fi

if [ ! -f "$BWA" ]; then
    echo "ERROR: BWA container not found: $BWA"
    errors=$((errors + 1))
fi

if [ -z "$assembly_file" ]; then
    echo "ERROR: No assembly file provided. Usage: sbatch arima_mapping_.sh <assembly.fasta>"
    errors=$((errors + 1))
elif [ ! -f "$assembly_file" ]; then
    echo "ERROR: Assembly file not found: $assembly_file"
    errors=$((errors + 1))
fi

if [ ! -d "$hic_dir" ]; then
    echo "ERROR: Hi-C directory not found: $hic_dir"
    errors=$((errors + 1))
fi

if [ -z "$H1" ]; then
    echo "ERROR: No R1 Hi-C file found in $hic_dir"
    errors=$((errors + 1))
fi

if [ -z "$H2" ]; then
    echo "ERROR: No R2 Hi-C file found in $hic_dir"
    errors=$((errors + 1))
fi

if [ -z "${TMPDIR:-}" ]; then
    echo "ERROR: TMPDIR is not set (are you running inside a SLURM job?)"
    errors=$((errors + 1))
fi

if [ -z "${SLURM_CPUS_PER_TASK:-}" ]; then
    echo "ERROR: SLURM_CPUS_PER_TASK is not set (are you running inside a SLURM job?)"
    errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
    echo "Aborting: $errors error(s) found above. Fix and resubmit."
    exit 1
fi

echo "All pre-flight checks passed."
echo "Hi-C forward: $H1"
echo "Hi-C reverse: $H2"
echo "hic_dir: $hic_dir"
echo "H1: $H1"
echo "H2: $H2"
echo "Assembly file: $assembly_file"
echo "Output file: $output_file"

temp="$TMPDIR/${output_file}"
mkdir -p "$temp"
echo "Temp dir: $temp"

##########################################################################
#------------Main Pipeline step------------------------------------------#
##########################################################################
singularity exec --bind /scratch $FASTP fastp \
    -i "$H1" -I "$H2" \
    -o "${output_file}_R1_trim.fastq.gz" \
    -O "${output_file}_R2_trim.fastq.gz" \
    --detect_adapter_for_pe \
    --disable_quality_filtering \
    --thread "$SLURM_CPUS_PER_TASK" \
&& singularity exec --bind /scratch $PAIRTOOLS samtools faidx "$assembly_file" \
&& cut -f1,2 "${assembly_file}.fai" > "${output_file}.genome" \
&& singularity exec --bind /scratch $BWA bwa index "$assembly_file" \
&& singularity exec --bind /scratch $BWA bwa mem -5SP -T0 -t"$SLURM_CPUS_PER_TASK" "$assembly_file" \
    "${output_file}_R1_trim.fastq.gz" "${output_file}_R2_trim.fastq.gz" \
    -o "${output_file}.aligned.sam" \
&& singularity exec --bind /scratch $PAIRTOOLS pairtools parse \
    --min-mapq 40 \
    --walks-policy 5unique \
    --max-inter-align-gap 30 \
    --nproc-in "$SLURM_CPUS_PER_TASK" \
    --nproc-out "$SLURM_CPUS_PER_TASK" \
    --chroms-path "${output_file}.genome" \
    "${output_file}.aligned.sam" > "${output_file}.parsed.pairsam" \
&& singularity exec --bind /scratch,$TMPDIR $PAIRTOOLS pairtools sort \
    --nproc "$SLURM_CPUS_PER_TASK" \
    --tmpdir="$temp" \
    "${output_file}.parsed.pairsam" > "${output_file}.sorted.pairsam" \
&& singularity exec --bind /scratch $PAIRTOOLS pairtools dedup \
    --nproc-in "$SLURM_CPUS_PER_TASK" \
    --nproc-out "$SLURM_CPUS_PER_TASK" \
    --mark-dups \
    --output-stats "${output_file}.stats.txt" \
    --output "${output_file}.dedup.pairsam" \
    "${output_file}.sorted.pairsam" \
&& singularity exec --bind /scratch $PAIRTOOLS pairtools split \
    --nproc-in "$SLURM_CPUS_PER_TASK" \
    --nproc-out "$SLURM_CPUS_PER_TASK" \
    --output-pairs "${output_file}.mapped.pairs" \
    --output-sam "${output_file}.unsorted.bam" \
    "${output_file}.dedup.pairsam" \
&& singularity exec --bind /scratch,$TMPDIR $PAIRTOOLS samtools sort \
    -@"$SLURM_CPUS_PER_TASK" \
    -T "${temp}/${output_file}_temp.bam" \
    -o "${output_file}.mapped.PT.bam" \
    "${output_file}.unsorted.bam" \
&& singularity exec --bind /scratch $PAIRTOOLS samtools index "${output_file}.mapped.PT.bam" \
&& rm -f \
    "${output_file}.aligned.sam" \
    "${output_file}.parsed.pairsam" \
    "${output_file}.sorted.pairsam" \
    "${output_file}.unsorted.bam" \
    "${output_file}.mapped.pairs" \
    "${output_file}.genome" \
    "${assembly_file}.sa" \
    "${assembly_file}.amb" \
    "${assembly_file}.ann" \
    "${assembly_file}.pac" \
    "${assembly_file}.bwt"

echo "Processing complete for $output_file"
echo "Done"
exit 0
