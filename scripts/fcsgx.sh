#!/bin/bash --login
 
#---------------
#fcsgx.sh : runs the NCBI Foreign Contamination Screen (fcs) tool for identifying and removing contaminant sequences in genome assemblies 
#---------------
#Requested resources:
#SBATCH --account=pawsey1348
#SBATCH --job-name=fcs-gx
#SBATCH --partition=highmem
 
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --time=24:00:00
#SBATCH --mem=900G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=nicholas.stratmann@utas.edu.au
#SBATCH --error=%x-%j.err

date=$(date +%y%m%d)

echo "========================================="
echo "SLURM_JOB_ID = $SLURM_JOB_ID"
echo "SLURM_NODELIST = $SLURM_NODELIST"
echo "DATE: $date"
echo "========================================="

#---------------
# Load modules
module load singularity/3.11.4-nompi
#---------------
# Define variables

fasta="$1"
taxid=$(grep '^taxid=' ../config.ini | cut -d '=' -f2)
SIF="/software/projects/pawsey1348/singularity/fcs-gx_latest.sif"

echo "fasta file: $fasta"
echo "NCBI taxon ID: $taxid"
echo "fscgx location: $SING"

# Path to the database
GXDB_LOC="/scratch/pawsey1348/nstratmann/GT16699/NCBI"

# Specify the number of cores (GitHub recommends 48 cores which is approx 24 CPUs)
GX_NUM_CORES=48

#---------------
# Run fcs-gx ##changed as I don't have .py in my container 
singularity exec $SIF \
    /app/bin/run_gx \
    --fasta $fasta \
    --tax-id $taxid \
    --gx-db /scratch/pawsey1348/nstratmann/GT16699/NCBI/all \
    --out-dir "./gx_out"
#---------------
#Successfully finished
echo "Done"
exit 0
