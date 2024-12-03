Running on a cluster
====================



Julia on HPC systems
--------------------






Installing Julia yourself
-------------------------




      


Installing packages
~~~~~~~~~~~~~~~~~~~




MPI configuration 
-----------------

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



Running on GPUs 
---------------

Julia packages for running code on GPUs (e.g. CUDA.jl and AMDGPU.jl) need both GPU drivers 
and development toolkits installed on the system you're using. On a cluster these are normally 
available through environment modules which need to be loaded before importing and using 
the Julia GPU package.

On NVIDIA GPUs, the CUDA.jl package needs NVIDIA drivers and toolkits. 
When installing the CUDA.jl package and importing it, Julia will look for libraries in the 
``CUDA_PATH`` (or ``CUDA_HOME``) environment variable. If these are not found they will be 
automatically installed but it's strongly recommended to use instead optimised pre-installed 
libraries. These are typically available in environment modules ``CUDA``, ``cuDNN`` etc.

For example:

.. code-block:: console

   $ module load CUDA
   $ julia

.. code-block:: julia

   using Pkg
   Pkg.add("CUDA")

   using CUDA
   CUDA.versioninfo()   


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
   addprocs(SlurmManager(4), partition="cpu", t="00:5:00", A="p200051", qos="short")
   # if using reservation:
   #addprocs(SlurmManager(4), partition="cpu", t="00:5:00", A="p200051", reservation="2022-11-enccs-julia-cpu")

   # let workers do some work
   for i in workers()
       id, pid, host = fetch(@spawnat i (myid(), getpid(), gethostname()))
       println(id, " " , pid, " ", host)
   end

   # The Slurm resource allocation is released when all the workers have exited
   for i in workers()
       rmprocs(i)
   end


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

        @btime mean(pmap(estimate_pi, $chunks))

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


.. keypoints::

   - Julia can usually be installed and configured without too much hassle on HPC systems.
   - ClusterManagers is a useful package for working interactively on a cluster through the Julia REPL.
   - For non-interactive work, Julia jobs can also be submitted through the scheduler.
