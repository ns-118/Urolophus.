#!/bin/bash
#SBATCH --account=pawsey1348
#SBATCH --partition=copy
#SBATCH --time=48:00:00
#SBATCH --ntasks=1
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=nicholas.stratmann@utas.edu.au

module load singularity/4.1.0-slurm

singularity exec /software/projects/pawsey1348/singularity/fcs-gx_latest.sif \
    /app/bin/sync_files get \
    --mft https://ftp.ncbi.nlm.nih.gov/genomes/TOOLS/FCS/database/latest/all.manifest \
    --dir /scratch/pawsey1348/nstratmann/GT16699/NCBI
