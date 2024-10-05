#!/usr/bin/env/bash

# Setup script to install tools for NGS pipeline using Bioconda

# Ensure the script is run as a superuser
if [ "$EUID" -ne 0 ]
  then echo "Please run as root using sudo"
  exit
fi

echo "Starting the setup process..."

# Install Miniconda if it's not already installed
if ! command -v conda &> /dev/null
then
    echo "Miniconda not found, installing Miniconda..."
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda
    export PATH="$HOME/miniconda/bin:$PATH"
    source $HOME/miniconda/etc/profile.d/conda.sh
    conda init bash
else
    echo "Conda is already installed."
fi

# Add Bioconda channels if not already added
echo "Setting up Bioconda channels..."
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge

# Create a conda environment for the NGS pipeline tools
echo "Creating a new conda environment 'ngs-pipeline'..."
conda create -y -n ngs-pipeline

# Activate the environment
echo "Activating the environment..."
source activate ngs-pipeline

# Install tools using Bioconda
echo "Installing FastQC..."
conda install -y fastqc

echo "Installing Fastp..."
conda install -y fastp

echo "Installing BWA..."
conda install -y bwa

echo "Installing Samtools..."
conda install -y samtools

echo "Installing BCFtools..."
conda install -y bcftools

# Verify installation
echo "Verifying installations..."
fastqc --version
fastp --version
bwa
samtools --version
bcftools --version

echo "Setup completed successfully!"