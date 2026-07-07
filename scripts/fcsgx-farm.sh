#!/bin/bash

# Job 1: Process hap1
for filename in *hap1_scaffolds_final.fa; do
    sbatch fcsgx.sh "$filename"
done


# Job 2: Process hap2
for filename in *hap2_scaffolds_final.fa; do
    sbatch fcsgx.sh "$filename"
done#!/bin/bash
