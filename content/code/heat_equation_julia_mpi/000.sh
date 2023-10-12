#!/bin/bash -l
#SBATCH -A project_465000693
#SBATCH -t 00:15:00
#SBATCH -p small
#SBATCH --nodes 1
#SBATCH --ntasks-per-node=8

module use /appl/local/csc/modulefiles
module load julia

# Instantiate the project environment
julia --project -e 'using Pkg; Pkg.instantiate()'

# Run the julia script
#julia --project hello.jl

#mpiexecjl -np 4 julia --project hello.jl
~/.julia/bin/mpiexecjl -n 8 julia --project main.jl test.yml

