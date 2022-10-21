Running on a cluster
====================

.. questions::

   - How should Julia be run on a cluster?

.. instructor-note::

   - 10 min teaching
   - 10 min exercises

Julia on HPC systems
--------------------

Despite rapid growth in the HPC domain in recent years, Julia is still not considered as mainstream 
as C/C++ and Fortran in the HPC world, and even Python is more commonly used (and generally available) 
than Julia. Fortunately, even if Julia is not already available as an environment module on your 
favorite cluster, it is easy to install Julia from scratch. Moreover, there is little reason to 
expect the performance of official Julia binaries to be any worse compared to if a system administrator 
built Julia from scratch with architecture-specific optimization. 

An overview 


JULIA_DEPOT_PATH
----------------

On a cluster it is often recommended to install own programs and packages in a directory different 
from the home directory (``$HOME``). The ``JULIA_DEPOT_PATH`` variable controls where Julia's 
package manager (as well as Julia's code loading mechanisms) looks for package registries, 
installed packages, named environments, repo clones, cached compiled package images, configuration 
files, and the default location of the REPL's history file.

Since the available file systems can differ significantly between HPC centers, 
it is hard to make a general statement about where the Julia depot folder should be placed. 
Generally speaking, the file system hosting the Julia depot should have

- Good parallel I/O
- No tight quotas on disk space or number of files
- Read and write access by the user
- No mechanism for the automatic deletion of unused files (or the depot should be excluded as an exception)

On some systems, it resides in the user's home directory. On other systems, it is put on a parallel 
scratch file system.

To prepend the ``JULIA_DEPOT_PATH`` variable with a new directory, type 
``export JULIA_DEPOT_PATH="/some/recommended/directory:$JULIA_DEPOT_PATH"``

Recommendations for using Julia on HPC systems, along with a listing of HPC systems around the world 
where Julia is installed and documented, can be found at https://github.com/hlrs-tasc/julia-on-hpc-systems.


Configuration of MPI
--------------------

MPI.jl can use either a JLL-provided MPI library, which can be automatically installed when installing 
MPI.jl, or a system-provided MPI backend. Normally the latter option is appropriate 
on an HPC cluster. The `MPIPreferences.jl <https://juliaparallel.org/MPI.jl/latest/reference/mpipreferences/>`__ 
package, based on `Preferences.jl <https://github.com/JuliaPackaging/Preferences.jl/>`__ which is 
used to store various package configuration switches in persistent TOML files, 
is used to select which MPI implementation to use. 

To install and configure MPI.jl with a particular MPI backend on a cluster, first load the 
preferred MPI library, e.g.

.. code-block:: console

   $ module load OpenMPI

Then, in a Julia session:

.. code-block:: julia

   using Pkg
   Pkg.add("MPI")
   Pkg.add("MPIPreferences")

   using MPIPreferences
   MPIPreferences.use_system_binary()

This will create a file ``LocalPreferences.toml`` in the default Julia directory, e.g. 
``$HOME/.julia/environments/v1.8``, with content similar to the following:

.. code-block:: toml

   [MPIPreferences]
   _format = "1.0"
   abi = "OpenMPI"
   binary = "system"
   libmpi = "libmpi"
   mpiexec = "mpiexec"   






ClusterManagers
---------------

`ClusterManagers.jl <https://github.com/JuliaParallel/ClusterManagers.jl>`__ is a package for 
interactive HPC work with all commonly used HPC scheduling systems, including SLURM, PBS, 
LSF, SGE, HTCondor, Kubernetes, etc.
