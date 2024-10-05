#!/usr/bin/env/bash


# Reference genome
REFERENCE="reference1.fasta"

# List of datasets (sample names without _R1/_R2.fastq.gz suffixes)
samples=("ACBarrie" "Alsen" "Baxter" "Chara" "Drysdale")

# Create output directories for each step
mkdir -p fastqc1_output trimming1_output mapping1_output variant1_calls_output filtered1_variants_output

# Index the reference genome (if not already done)
if [ ! -f "${REFERENCE}.bwt" ]; then
    bwa index $REFERENCE
fi

# Loop through each sample
for sample in "${samples[@]}"; do
    echo "Processing $sample ..."

    # Define the input file names
    R1="${sample}_R1.fastq.gz"
    R2="${sample}_R2.fastq.gz"

    # 1. Run FastQC for quality control
    echo "Running FastQC on $sample..."
    fastqc $R1 $R2 -o fastqc1_output/

    # 2. Trim the reads using Fastp
    echo "Trimming reads for $sample..."
    fastp -i $R1 -I $R2 -o trimming1_output/${sample}_R1_trimmed.fastq.gz -O trimming1_output/${sample}_R2_trimmed.fastq.gz --dont_overwrite_null_reads

    # 3. Map the reads to the reference genome using BWA
    echo "Mapping reads for $sample..."
    bwa mem $REFERENCE trimming1_output/${sample}_R1_trimmed.fastq.gz trimming1_output/${sample}_R2_trimmed.fastq.gz > mapping1_output/${sample}_mapped.sam

    # Convert SAM to BAM, sort, and index
    echo "Converting and sorting BAM for $sample..."
    samtools view -Sb mapping1_output/${sample}_mapped.sam > mapping1_output/${sample}_mapped.bam
    samtools sort mapping1_output/${sample}_mapped.bam -o mapping1_output/${sample}_sorted.bam
    samtools index mapping1_output/${sample}_sorted.bam

    # 4. Variant calling using BCFtools
    echo "Calling variants for $sample..."
    bcftools mpileup -Ou -f $REFERENCE mapping1_output/${sample}_sorted.bam | bcftools call -mv -Ov -o variant1_calls_output/${sample}_variants.vcf

    # 5. Filter variants
    echo "Filtering variants for $sample..."
    bcftools filter -s LowQual -e 'QUAL<20 || INFO/DP<10' -O v -o filtered1_variants_output/${sample}_filtered_variants.vcf variant1_calls_output/${sample}_variants.vcf

    echo "$sample processing completed."
done