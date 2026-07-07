#!/bin/bash --login
 
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
#---------------

echo "========================================="
echo "SLURM_JOB_ID = $SLURM_JOB_ID"
echo "SLURM_NODELIST = $SLURM_NODELIST"
echo "DATE: $date"
echo "========================================="

#---------------
# Define variables

# Path to the database
GXDB_LOC="/scratch/pawsey1348/nstratmann/GT16699/NCBI"

# Specify the number of cores (GitHub recommends 48 cores which is approx 24 CPUs)
GX_NUM_CORES=48

# Specify the NCBI taxon ID for the current sample
taxid=215367

fasta="$1"
echo "fasta file: $fasta"

sample=$1
rundir=$2
assembly=$3

fasta="$rundir/$sample/assemblies/genome/$assembly.v129mh.fasta"
out_dir="$rundir/$sample/assemblies/genome/NCBI"
action_report="$rundir/$sample/assemblies/genome/NCBI/$assembly.v129mh.7898.fcs_gx_report.txt"
output_file="$rundir/$sample/assemblies/genome/NCBI/$assembly.filter_report.txt"
review_report="$rundir/$sample/assemblies/genome/NCBI/$assembly.review_scaffolds_1kb.txt"
filter_in="$rundir/$sample/assemblies/genome/NCBI"
contig_count="$rundir/$sample/assemblies/genome/NCBI/$assembly.contig_count_500bp.txt"
final_out="$rundir/$sample/assemblies/genome"

#remove the exclude and trim seqeunces 
python3 $SING/fcs.py --image=$SING/fcs-gx.sif clean genome -i $fasta --action-report "$action_report" --output "$out_dir/$assembly.v129mh.rc.fasta" --contam-fasta-out "$out_dir/$sample.contam.fasta"
wait 

# count the number of contigs and the number of base pairs being removed across EXCLUDE and TRIM 
count=$(grep -w EXCLUDE "$action_report" | cut -f 1 | sort -u | wc -l)
bp=$(grep -w EXCLUDE "$action_report" | awk '{sum+=$3-$2+1}END{print sum}')
echo "EXCLUDE $count $bp" >> "$output_file"

count=$(grep -w TRIM "$action_report" | cut -f 1 | sort -u | wc -l)
bp=$(grep -w TRIM "$action_report" | awk '{sum+=$3-$2+1}END{print sum}')
echo "TRIM $count $bp" >> "$output_file"

#generate a txt file with the name of the contigs that are in review that are less that 1000bp.
grep -w REVIEW "$action_report" | awk '$4 <= 1000' | awk '{print $1}' > "$review_report"

# remove these contigs 
singularity run $SING/bbmap:39.01.sif filterbyname.sh in="$out_dir/$assembly.v129mh.rc.fasta" out="$out_dir/$assembly.v129mh.rf.fa" names="$review_report" exclude 

# Wait for the first bbmap script to complete before moving on
wait

grep -v '^>' $out_dir/$assembly.v129mh.rf.fa | awk 'length($0) < 500 {count++} END {print "Number of contigs less than 500bp:", count}' > "$contig_count"



#---------------
#Successfully finished
echo "Done"
exit 0
