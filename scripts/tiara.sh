#!/bin/bash --login
 
#---------------
#tiara.sh : runs the program Tiara (v.1.0.3) to search for additional decontamination in the assemblies, particularity Mitochondrial 
 
#---------------
#Requested resources:
#SBATCH --account=pawsey1348
#SBATCH --job-name=tiara
#SBATCH --partition=highmem

#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --time=24:00:00
#SBATCH --mem=900G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=nicholas.stratmann@utas.edu.au

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
# Load modules
module load singularity/3.11.4-nompi
SING=/software/projects/pawsey1348/singularity
#---------------
# Define variables

# specify the output directory
out_dir="tiara"
#---------------
# Run tiara

for fasta in *scaffolds_final.fa; do
    # Use regular expression to extract the sample prefix
    sample=$(echo "$fasta" | grep -o -E '(hap[12]|pri)')

    # Run tiara
echo "SING is: $SING"
    singularity exec "$SING/tiara:1.0.3.sif" tiara -i "$fasta" -o "$out_dir/$sample.tiara.txt" -m 1000 --tf mit pla pro -
done


#---------------
#Successfully finished
echo "Done"
exit 0
