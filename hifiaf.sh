#!/bin/bash --login

#---------------
# hifiaf.sh : runs HiFiAdapterFilt

#---------------
#SBATCH --account=pawsey1348
#SBATCH --job-name=hifiaf
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --time=15:00:00
#SBATCH --mem=64G
#SBATCH --export=ALL
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

date=$(date +%y%m%d)

echo "========================================="
echo "SLURM_JOB_ID = $SLURM_JOB_ID"
echo "SLURM_NODELIST = $SLURM_NODELIST"
echo "DATE: $date"
echo "========================================="

module load singularity/4.1.0-slurm

export SING="/software/projects/pawsey1348/singularity"
IMAGE="$SING/hifiadapterfilt_v2.0.sif"

full_path=$(pwd)

if [[ $full_path =~ /([^/]+)/data/raw/hifi ]]; then
  sample=${BASH_REMATCH[1]}
  echo "Sample: $sample"
else
  echo "Pattern not found in the path."
fi

processed_dir="$(dirname "$(dirname "$full_path")")/processed"
echo "Target data directory is $processed_dir"

stats_dir="$(dirname "$(dirname "$(dirname "$full_path")")")/stats/hifiadapterfilt"
echo "Target stats directory is $stats_dir"

# Prior DB check
echo "Checking BLAST database inside container..."
singularity exec \
  --bind /scratch/pawsey1348/nstratmann:/scratch/pawsey1348/nstratmann \
  --env PATH="/scratch/pawsey1348/nstratmann/pauci/data/raw/hifi/HiFiAdapterFilt/DB:\$PATH" \
  "$IMAGE" \
  bash -c 'DBpath=$(echo $PATH | sed "s/:/\n/g" | grep "HiFiAdapterFilt/DB" | head -n 1) && echo "$DBpath" && ls ${DBpath}/pacbio_vectors_db.nin'
if [ $? -ne 0 ]; then
  echo "ERROR: BLAST database not found. Aborting at $(date)"
  exit 1
fi
echo "BLAST database found. Proceeding..."
echo "Starting HiFiAdapterFilt at $(date)"

# Run HiFiAdapterFilt (allow non-zero exit due to known cleanup bug)
singularity exec \
  --bind /scratch/pawsey1348/nstratmann:/scratch/pawsey1348/nstratmann \
  --env PATH="/scratch/pawsey1348/nstratmann/pauci/data/raw/hifi/HiFiAdapterFilt/DB:\$PATH" \
 "$IMAGE" \
  /scratch/pawsey1348/nstratmann/pauci/data/raw/hifi/HiFiAdapterFilt/hifiadapterfilt.sh \
    -p all  \
    -t 32 \
    -o .
2> hifiadapterfilt.stderr.log || true

# ---- SUCCESS CRITERION ----
# HiFiAdapterFilt is considered successful if it produced filtered FASTQ files
if ls *.filt.fastq.gz >/dev/null 2>&1; then
  echo "HiFiAdapterFilt completed successfully at $(date)"
else
  echo "ERROR: HiFiAdapterFilt failed — no .filt.fastq.gz outputs found" >&2
  echo "See hifiadapterfilt.stderr.log for details" >&2
  exit 1
fi
# Move outputs
find . -type f -name "*.filt.fastq.gz" -exec mv {} "$processed_dir" \; \
  && echo "Filtered fastq files moved to target directory."

find . -type f -name "*.stats" -exec mv {} "$stats_dir" \; \
  && echo "Statistics files moved to stats directory."

find . -type f \( -name "*.blocklist" -o -name "*.blastout" \) -delete \
  && echo "Removed unwanted output files."

echo "Done"
exit 0
