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

To use ClusterManagers.jl we need access to Julia on the login node of a cluster. The following 
script uses the ``SlurmManager`` for HPC systems using the SLURM scheduler:

.. code-block:: julia

   using Distributed, ClusterManagers

   # request 4 tasks 
   addprocs(SlurmManager(4), partition="cpu", t="00:5:00", A="d2021-135-users")

   # let workers do some work
   for i in workers()
       id, pid, host = fetch(@spawnat i (myid(), getpid(), gethostname()))
       println(id, " " , pid, " ", host)
   end

   # The Slurm resource allocation is released when all the workers have exited
   for i in workers()
       rmprocs(i)
   end

.. callout:: Cluster-specifics

   .. tabs:: 

      .. tab:: Meluxina

         One unusual feature of Meluxina is that environment modules are not mounted on the login node. 
         Thus, to use Julia on the login node one needs to install it oneself. Fortunately this is 
         straightforward:

         .. code-block:: console

            $ curl -fsSL https://install.julialang.org | sh 

         Since your home directory on Meluxina is mounted on the high performance parallel Lustre 
         file system, you can safely install Julia in the default location under ``/home/users/``.

         To add parallel workers through ClusterManagers (replace the fields as needed):

         .. code-block:: julia

            using ClusterManagers
            addprocs(SlurmManager(8), partition="cpu", t="00:15:00", A="p200051", reservation="cpudev", q="dev")


.. challenge:: Use ClusterManagers.jl to launch parallel job

   Take the parallelised version of the :meth:`estimate_pi` function encountered in an 
   earlier exercise:

   .. literalinclude:: code/estimate_pi_distributed.jl
      :language: julia

   - Open a Julia REPL on the cluster login node. Import ClusterManagers, Distributed and BenchmarkTools.
   - Request one SLURM task with the :meth:`addprocs` method (see cluster-specific info above).
   - Define the :meth:`estimate_pi` function with the ``@everywhere`` macro.
   - Benchmark the serial version:
     
     .. code-block:: julia

        num_points = 10^9
        num_jobs = 100
        chunks = [num_points / num_jobs for i in 1:num_jobs]

        @btime mean(pmap(estimate_pi, chunks))

   - Now add 7 more cores by repeating the :meth:`addprocs` command and benchmark it again. 
     Note that you need to redefine :meth:`estimate_pi` every time you add workers!
   - Add another 8 workers and benchmark one final time.
   - Finally remove the workers to release the allocations.

   .. solution:: 

      Request 1 worker (core). Replace "PROJECT-ID" and "QOS" appropriately:

      .. code-block:: julia

         addprocs(SlurmManager(1), partition="cpu", t="00:5:00", A="PROJECT-ID", qos="QOS")

      Then define the function on the worker:

      .. literalinclude:: code/estimate_pi_distributed.jl
         :language: julia

      Run on all the cores and time it:

      .. code-block:: julia

         num_points = 10^9
         num_jobs = 100
         chunks = [num_points / num_jobs for i in 1:num_jobs]

         @btime mean(pmap(estimate_pi, chunks))

      Repeat the process with 7 more cores:

      .. code-block:: julia

         addprocs(SlurmManager(7), partition="cpu", t="00:5:00", A="PROJECT-ID", qos="QOS")

      .. literalinclude:: code/estimate_pi_distributed.jl
         :language: julia

      .. code-block:: julia

         @btime mean(pmap(estimate_pi, chunks))

      The redo exact same thing with 8 more workers.


.. challenge:: Run an MPI job

   Take the MPI version of the :meth:`estimate_pi` code that we encountered in the MPI episode:

   .. solution:: estimate_pi.jl

      .. literalinclude:: code/estimate_pi_mpi_compact.jl
         :language: julia

   Use the following batch script to submit a Julia job to the queue (modify the SLURM options 
   as needed):

   .. literalinclude:: code/submit_meluxina.sh
      :language: bash
   
   Try running it with different number of nodes and/or cores. Does it scale well up to a full node?