#These are scripts used for reference genome assembly, cloned from e-dejong/Ocean-Omics-Ref-Genomes 

# (1) hifiaf.sh had issues running, this has been modified from it's base a little bit. 
# This was modified using Claude. Had issues linking BLAST database and binding this. 
# Eventually issue was solved. 

#This step is designed to remove adaptors from the .bam files, it removes adaptors by using BLAST
#and matching these. If they match they are removed. PacBio normally remove adaptors, but this step
#did remove (in no particular order) 5, 27 and 4 from each of the 3 .bam files 
#following this step, it converted .bam files to .fastq.gz file types. 

#(2) currently running meryl.sh 

