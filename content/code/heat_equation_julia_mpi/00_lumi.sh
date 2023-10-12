#!/bin/bash -l
#SBATCH -A project_465000693
#SBATCH -t 00:10:00
#SBATCH -p small
#SBATCH --nodes 1
#SBATCH --ntasks-per-node=8

module use /appl/local/csc/modulefiles
module load julia

# Instantiate the project environment
julia --project -e 'using Pkg; Pkg.instantiate()'

~/.julia/bin/mpiexecjl -n 8 julia --project src/main.jl test.yml

