#!/bin/bash --login

#---------------
#gscope.sh : runs GenomeScope2 for infering genome properties from unassembled sequencing data

#---------------
#Requested resources:
#SBATCH --account=pawsey1348
#SBATCH --job-name=gscope
#SBATCH --partition=work

#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --time=00:30:00
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
tolid=$(grep '^tolid=' ../config.ini | cut -d '=' -f2)

echo "sample: $sample"
echo "ToLID: $tolid"


#---------------
# Run genomescope2
singularity run $SING/genomescope2:2.0.1.sif genomescope2 -i "$sample.meryl.hist" -o genomescope -k 31 --testing

# alternative with -l 50
#singularity run $SING/genomescope2:2.0.sif genomescope2 -i "$sample.meryl.hist" -l 50 -o genomescope -k 31 --testing

#---------------
# copy data to Acacia s3 storage
#echo "Backing up genomescope results... "

# re-name to include ToLID
#for file in "genomescope/"*; do
   # mv "$file" "genomescope/${tolid}_genomescope_$(basename "$file")"
#done

#rclone copy "genomescope/" "pawsey0812:oceanomics-assemblies/${sample}/genomescope" --checksum


#---------------
#Successfully finished
echo "Done"
exit 0
