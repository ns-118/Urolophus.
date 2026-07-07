#!/bin/bash

# # Job 1: Scaffold hap1 assembly
for filename in *hifiasm*hap1.p_ctg.fasta; do
    bam="${filename/hap1.p_ctg.fasta/hap1.mapped.PT.bam}"
    sbatch yahs.sh "$filename" "$bam"
done

# Job 2: Scaffold hap2 assembly
for filename in *hifiasm*hap2.p_ctg.fasta; do
    bam="${filename/hap2.p_ctg.fasta/hap2.mapped.PT.bam}"
    sbatch yahs.sh "$filename" "$bam"
done
