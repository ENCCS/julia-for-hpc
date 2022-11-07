#!/bin/bash -l
#SBATCH -A p200051
#SBATCH -t 00:10:00
#SBATCH -q short
#SBATCH -p cpu
#SBATCH -N 1
#SBATCH --ntasks-per-node=8

module load OpenMPI
module load Julia

n=$SLURM_NTASKS
srun -n $n julia estimate_pi.jl         
