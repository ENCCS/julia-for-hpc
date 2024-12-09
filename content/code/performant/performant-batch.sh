#!/bin/bash -l
#SBATCH --account=project_465001310
#SBATCH --partition=small
#SBATCH --time=00:15:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2000

module use /appl/local/csc/modulefiles
module load julia

julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. performant-template.jl

