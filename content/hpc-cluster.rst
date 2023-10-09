Using Julia on an HPC cluster
=============================

.. questions::

   - How do we run Julia in an HPC cluster?
   - How can we do parallel computing with Julia on an HPC cluster?

.. instructor-note::

   - 30 min teaching
   - 30 min exercises

Julia on HPC systems
--------------------
Despite rapid growth in the HPC domain in recent years, Julia is still not considered as mainstream as C/C++ and Fortran in the HPC world, and even Python is more commonly used (and generally available) than Julia.
Fortunately, even if Julia is not already available as an environment module on your favorite cluster, it is easy to install Julia from scratch.
Moreover, there is little reason to expect the performance of official Julia binaries to be any worse than if a system administrator built Julia from scratch with architecture-specific optimization.
`Julia on HPC clusters <https://juliahpc.github.io/JuliaOnHPCClusters/>`_ gives an overview of the availability and documentation of Julia on a range of HPC systems around the world, including EuroHPC systems.


Terminology of an HPC cluster
---------------------------
HPC cluster consists of networked computers called **nodes**.
The nodes are separated into user-facing **login nodes** and nodes that are intended for heavy computing called **compute nodes**
The nodes are colocated and connected using a **high-speed network** minimize communication latency and maximize performance at scale.
A **parallel file system** provides a system-wide mass storage capacity.

HPC clusters use the **Linux operating system**.
Many problems that users have with using a cluster stem from a lack of Linux knowledge.

Clusters also use **module environments** to manage software environments by setting environment variables and loading other modules as dependencies.
We demonstrate the popular **Lmod** software and how to use Julia module environments with Lmod.

Finally, HPC clusters use a **workload manager** to manage resources and run jobs on compute nodes.
We demonstrate the popular **Slurm** workload manager and how to run Julia programs that perform various forms of parallel computing with Slurm.
We refer to a single workload run through a workload manager as a **job**.


Using module environments
-------------------------
We can load a shared Julia installation as a module environment if one is available.
The module environment modifies the path to make the Julia command line client available and may set environment variables for Julia thread count and modify the depot and load paths to make shared packages available.

Available module environments are controlled by the module path (:code:`MODULEPATH`) environment variable.
Sometimes, it is necessary to add custom directories to the module path as follows:

.. code-block:: bash

   module use <path>

We can check the availability of a Julia module environment as follows.

.. code-block:: bash

   module avail julia

If the Julia module is not available, we can install Julia manually to the cluster.
On the other hand, if a Julia module is available, we can take a look at what the Julia sets when it is loaded as follows:

.. code-block:: bash

   module show julia

We can load the Julia module as follows:

.. code-block:: bash

   module load julia

We can list the loaded module and check that Julia is available as follows:

.. code-block:: bash

   module list
   julia --version

In case everything works well, we should be ready to move forward.

.. tabs::

   .. tab:: LUMI CPU

      .. code-block::

          # Add CSC's local module files to the module path
          module use /appl/local/csc/modulefiles

          # Load the Julia module
          module load julia

   .. tab:: LUMI GPU

      .. code-block::

          # Add CSC's local module files to the module path
          module use /appl/local/csc/modulefiles

          # Load the Julia AMDGPU module
          module load julia-amdgpu


Running interactive jobs
------------------------
We can launch an interactive job on a compute node via Slurm.
Interactive jobs are useful for developing, testing, debugging, and exploring Slurm jobs.
We can run an interactive job as follows:

.. code-block:: bash

   srun [options] --pty bash

The :code:`srun` command launches the job with options that declare the resources we want to reserve, :code:`--pty` flag attached a pseudoterminal to the job and the argument to run :code:`bash`.

.. tabs::

   .. tab:: LUMI CPU (small)

      .. code-block:: bash

         srun \
             --account="<project>" \
             --partition=small \
             --nodes=1 \
             --ntasks-per-node=1 \
             --cpus-per-task=2 \
             --mem-per-cpu=1000 \
             --time="00:15:00" \
             --pty \
             bash

   .. tab:: LUMI GPU (small-g)

      .. code-block:: bash

         srun \
             --account="<project>" \
             --partition=small-g \
             --nodes=1 \
             --ntasks-per-node=1 \
             --cpus-per-task=16 \
             --gpus-per-node=1 \
             --mem-per-cpu=1750 \
             --time="00:15:00" \
             --pty \
             bash


Running batch jobs
------------------
We can run batch jobs via Slurm.
We use batch jobs to run workloads from start to finish without interacting with them.
We can run a batch job as follows:

.. code-block:: bash

   sbatch [options] script.sh

The :code:`sbatch` command launches the batch job, with options that declare the resources we want to reserve, and the batch script :code:`script.sh` contains the commands to run the job.

.. tabs::

   .. tab:: LUMI CPU (small)

      .. code-block:: bash

         sbatch \
             --account="<project>" \
             --partition=small \
             --nodes=1 \
             --ntasks-per-node=1 \
             --cpus-per-task=2 \
             --mem-per-cpu=1000 \
             --time="00:15:00" \
             script.sh

      Often options are specified as comments in the batch ``script.sh`` as follows.

      .. code-block:: bash

         #!/bin/bash
         #SBATCH --account="<project>"
         #SBATCH --partition=small
         #SBATCH --nodes=1
         #SBATCH --ntasks-per-node=1
         #SBATCH --cpus-per-task=2
         #SBATCH --mem-per-cpu=1000
         #SBATCH --time="00:15:00"

   .. tab:: LUMI GPU (small-g)

      .. code-block:: bash

         srun \
             --account="<project>" \
             --partition=small-g \
             --nodes=1 \
             --ntasks-per-node=1 \
             --cpus-per-task=16 \
             --gpus-per-node=1 \
             --mem-per-cpu=1750 \
             --time="00:15:00" \
             script.sh

      Often options are specified as comments in the batch ``script.sh`` as follows.

      .. code-block:: bash

         #!/bin/bash
         #SBATCH --account="<project>"
         #SBATCH --partition=small-g
         #SBATCH --nodes=1
         #SBATCH --ntasks-per-node=1
         #SBATCH --cpus-per-task=16
         #SBATCH --gpus-per-node=1
         #SBATCH --mem-per-cpu=1750
         #SBATCH --time="00:15:00"


Running Julia application in a job
----------------------------------
Let's consider a standalone Julia application that contains the following files:

- :code:`Project.toml` for describing project metadata and dependencies.
- :code:`script.jl` for an entry point to run the desired Julia workload.
  Optionally, it can implement a command line client if we want to parse arguments that are supplied to the script.
- :code:`script.sh` for a batch script for setting up the Julia environment and running the Julia workload.

Below, we show examples of the batch script :code:`script.sh`.
We assume that our current working directory is the Julia application.

.. tabs::

   .. tab:: LUMI CPU

      .. code-block:: bash

         #!/bin/bash
         # Add CSC's local modulefiles to the modulepath
         module use /appl/local/csc/modulefiles

         # Load the Julia module
         module load julia

         # Instantiate the project environment
         julia --project=. -e 'using Pkg; Pkg.instantiate()'

         # Run the julia script
         julia --project=. script.jl

   .. tab:: LUMI GPU

      .. code-block:: bash

         #!/bin/bash
         # Add CSC's local modulefiles to the modulepath
         module use /appl/local/csc/modulefiles

         # Load the Julia AMDGPU module
         module load julia-amdgpu

         # Instantiate the project environment
         julia --project=. -e 'using Pkg; Pkg.instantiate()'

         # Run the julia script
         julia --project=. script.jl

Now, we can run the batch script as a batch job or supply the commands in the batch script individually to an interactive session.


Exercises
---------
In these exercises you should create the three files ``Project.toml``, ``script.jl``, and ``script.sh`` and run them via Slurm in the LUMI cluster.
If the course has a resource reservation, we can use the :code:`--reservation="<name>"` option to use it.


Run multithreaded job
^^^^^^^^^^^^^^^^^^^^^
Run the following files in a single node job with two CPU cores and one julia thread per core.

``Project.toml``

.. code-block:: toml

   # empty Project.toml

``script.jl``

.. code-block:: julia

   using Base.Threads
   a = zeros(Int, 2*nthreads())
   @threads for i in eachindex(a)
       a[i] = threadid()
   end
   println(a)

.. solution::

   ``script.sh``

   .. code-block:: bash

      #!/bin/bash
      #SBATCH --account="<project>"
      #SBATCH --partition=small
      #SBATCH --nodes=1
      #SBATCH --ntasks-per-node=1
      #SBATCH --cpus-per-task=2
      #SBATCH --mem-per-cpu=1000
      #SBATCH --time="00:15:00"

      module use /appl/local/csc/modulefiles
      module load julia
      julia --project=. -e 'using Pkg; Pkg.instantiate()'
      julia --project=. script.jl

   .. code-block:: bash

      sbatch script.sh


Run distributed job
^^^^^^^^^^^^^^^^^^^
Run the following files a single node job with three CPU cores and one julia process per core.

``Project.toml``

.. code-block:: toml

   [deps]
   Distributed = "8ba89e20-285c-5b6f-9357-94700520ee1b"

``script.jl``

.. code-block:: julia

   using Distributed
   addprocs(Sys.CPU_THREADS-1)

   @everywhere task() = myid()
   futures = [@spawnat id task() for id in workers()]
   outputs = fetch.(futures)
   println(outputs)

.. solution::

   ``script.sh``

   .. code-block:: bash

      #!/bin/bash
      #SBATCH --account="<project>"
      #SBATCH --partition=small
      #SBATCH --nodes=1
      #SBATCH --ntasks-per-node=1
      #SBATCH --cpus-per-task=3
      #SBATCH --mem-per-cpu=1000
      #SBATCH --time="00:15:00"

      module use /appl/local/csc/modulefiles
      module load julia
      julia --project=. -e 'using Pkg; Pkg.instantiate()'
      julia --project=. script.jl

   .. code-block:: bash

      sbatch script.sh


Run MPI job
^^^^^^^^^^^
Run the following files MPI code using two nodes with two slurm tasks per node and one CPU per task.

``Project.toml``

.. code-block:: toml

   [deps]
   MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195"

   [compat]
   MPI = "=0.20.8"

``script.jl``

.. code-block:: julia

   using MPI

   MPI.Init()
   comm = MPI.COMM_WORLD
   rank = MPI.Comm_rank(comm)
   size = MPI.Comm_size(comm)
   println("Hello from rank $(rank) out of $(size) from host $(gethostname()) and process $(getpid()).")
   MPI.Barrier(comm)

.. solution::

   ``script.sh``

   .. code-block:: bash

      #!/bin/bash
      #SBATCH --account="<project>"
      #SBATCH --partition=small
      #SBATCH --nodes=2
      #SBATCH --ntasks-per-node=2
      #SBATCH --cpus-per-task=1
      #SBATCH --mem-per-cpu=1000
      #SBATCH --time="00:15:00"

      module use /appl/local/csc/modulefiles
      module load julia
      julia --project=. -e 'using Pkg; Pkg.instantiate()'
      julia --project=. script.jl

   .. code-block:: bash

      sbatch script.sh


Run GPU job
^^^^^^^^^^^
Run the following files GPU code using one node with one slurm tasks per node, one GPU per node and sixteen CPUs per task.

``Project.toml``

.. code-block:: toml

   [deps]
   AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"

   [compat]
   AMDGPU = "=0.4.13"

``script.jl``

.. code-block:: julia

   using AMDGPU

   A = rand(2^9, 2^9)
   A_d = ROCArray(A)
   B_d = $A_d * $A_d

.. solution::

   ``script.sh``

   .. code-block:: bash

      #!/bin/bash
      #SBATCH --account=<project>
      #SBATCH --partition=small-g
      #SBATCH --time=00:15:00
      #SBATCH --nodes=1
      #SBATCH --ntasks-per-node=1
      #SBATCH --cpus-per-task=16
      #SBATCH --gpus-per-node=1
      #SBATCH --mem-per-cpu=1750

      module use /appl/local/csc/modulefiles
      module load julia-amdgpu
      julia --project=. -e 'using Pkg; Pkg.instantiate()'
      julia --project=. script.jl

   .. code-block:: bash

      sbatch script.sh

