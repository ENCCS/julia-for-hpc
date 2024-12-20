Julia on HPC cluster
====================


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
`Julia on HPC clusters <https://juliahpc.github.io/>`_ gives an overview of the availability and documentation of Julia on a range of HPC systems around the world, including EuroHPC systems.



Terminology of an HPC cluster
-----------------------------
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
We can load a Julia installation as a module environment if one is available.
The module environment modifies the path to make the Julia command line client available and may set environment variables for Julia thread count.

Available module environments are controlled by the module path (:code:`MODULEPATH`) environment variable.
Sometimes, it is necessary to add custom directories to the module path as follows:

.. code-block:: console

   $ module use <path>

We can check the availability of a Julia module environment as follows.

.. code-block:: console

   $ module avail julia

If the Julia module is not available, we can install Julia manually to the cluster.
On the other hand, if a Julia module is available, we can take a look at what the Julia sets when it is loaded as follows:

.. code-block:: console

   $ module show julia

We can load the Julia module as follows:

.. code-block:: console

   $ module load julia

We can list the loaded module and check that Julia is available as follows:

.. code-block:: console

   $ module list
   $ julia --version

In case everything works well, we should be ready to move forward.

.. demo:: Using Julia on the LUMI cluster.

   First, add CSC's local module files to the module path.

   .. code-block:: console

      $ module use /appl/local/csc/modulefiles

   The, load the Julia module.

   .. code-block:: console

      $ module load julia

   We can load MPI preferences to use system the MPI with MPI.jl as runtime.
   They are not required for installing MPI.jl.

   .. code-block:: console

       $ module load julia-mpi

   We can load AMDGPU preferences to use the system AMDGPU and ROCm with AMDGPU.jl at runtime.
   They are not required for installing AMDGPU.jl

   .. code-block:: console

       $ module load julia-amdgpu


Installing packages
-------------------
We can install Julia packages normally using the package manager on a login node in a cluster.
We also recommend to precompile Julia environments on the login node using them on the compute nodes.
Precompiling and installing Julia packages on a compute node may run into issues with limited temporary disk space and it consumes the resources allocated to the job.
Packages such as MPI.jl, CUDA.jl, AMDGPU.jl and other can be installed normally.
The cluster specific preferences are required only to use system installed MPI and GPU libraries at runtime.

.. demo:: Installing Julia packages on the LUMI cluster.

   Load the Julia module and start interactive Julia session with multiple threads to speed up package installation.

   .. code-block:: console 

      $ module use /appl/local/csc/modulefiles
      $ module load julia
      $ julia --threads 8

   In the Julia session, load the package manager and install packages for MPI, GPU and parallel computing.
   Finally, precompile the packages.

   .. code-block:: julia

      using Pkg
      Pkg.add("MPI")
      Pkg.add("AMDGPU")
      Pkg.add("ClusterManagers")
      Pkg.add("Dagger")
      Pkg.precompile()


Running interactive jobs
------------------------
We can launch an interactive job on a compute node via Slurm.
Interactive jobs are useful for developing, testing, debugging, and exploring Slurm jobs.
We can run an interactive job as follows:

.. code-block:: console

   $ srun [options] --pty bash

The :code:`srun` command launches the job with options that declare the resources we want to reserve, :code:`--pty` flag attached a pseudoterminal to the job and the argument to run :code:`bash`.

.. demo:: Running interactive CPU job on LUMI.

   .. code-block:: bash

      srun \
          --account=project_465001310 \
          --partition=debug \
          --nodes=1 \
          --ntasks-per-node=1 \
          --cpus-per-task=2 \
          --mem-per-cpu=1000 \
          --time="00:15:00" \
          --pty \
          bash

.. demo:: Running interactive GPU job on LUMI.

   .. code-block:: bash

      srun \
          --account=project_465001310 \
          --partition=dev-g \
          --nodes=1 \
          --ntasks-per-node=1 \
          --cpus-per-task=16 \
          --gpus-per-node=1 \
          --mem-per-cpu=1750 \
          --time="00:15:00" \
          --pty \
          bash

.. demo:: Checking partitions on LUMI.

   The above job submission use the debug partition for quick testing.
   We should change the partition for real workloads that require more resources.
   One way to inspect partitions, is to use the `scontrol` as follows:

   .. code-block:: console

      $ scontrol show partition | less -S


Running batch jobs
------------------
We can run batch jobs via Slurm.
We use batch jobs to run workloads from start to finish without interacting with them.
We can run a batch job as follows:

.. code-block:: console

   $ sbatch [options] batch.sh

The :code:`sbatch` command launches the batch job, with options that declare the resources we want to reserve, and the batch script :code:`batch.sh` contains the commands to run the job.

.. demo:: Running CPU batch job on LUMI.

   We can write ``batch.sh`` file as follows:

   .. code-block:: bash

      #!/bin/bash
      echo "Hello, world!"

   .. code-block:: console

      $ sbatch \
          --account=project_465001310 \
          --partition=debug \
          --nodes=1 \
          --ntasks-per-node=1 \
          --cpus-per-task=2 \
          --mem-per-cpu=1000 \
          --time="00:15:00" \
          batch.sh

   Alternatively, we can specify the options as comments in the batch ``batch.sh`` and run in without option using `sbatch`:

   .. code-block:: bash

      #!/bin/bash
      #SBATCH --account=project_465001310
      #SBATCH --partition=debug
      #SBATCH --nodes=1
      #SBATCH --ntasks-per-node=1
      #SBATCH --cpus-per-task=2
      #SBATCH --mem-per-cpu=1000
      #SBATCH --time="00:15:00"
      echo "Hello, world!"

   .. code-block:: console

      $ sbatch batch.sh

.. demo:: Running GPU batch job on LUMI.

   We can write ``batch.sh`` file as follows:

   .. code-block:: bash

      #!/bin/bash
      echo "Hello, world!"

   .. code-block:: console

      $ sbatch \
          --account=project_465001310 \
          --partition=dev-g \
          --nodes=1 \
          --ntasks-per-node=1 \
          --cpus-per-task=16 \
          --gpus-per-node=1 \
          --mem-per-cpu=1750 \
          --time="00:15:00" \
          batch.sh

   Alternatively, we can specify the options as comments in the batch ``batch.sh`` and run in without option using `sbatch`:

   .. code-block:: bash

      #!/bin/bash
      #SBATCH --account=project_465001310
      #SBATCH --partition=dev-g
      #SBATCH --nodes=1
      #SBATCH --ntasks-per-node=1
      #SBATCH --cpus-per-task=16
      #SBATCH --gpus-per-node=1
      #SBATCH --mem-per-cpu=1750
      #SBATCH --time="00:15:00"
      echo "Hello, world!"

   .. code-block:: console

      $ sbatch batch.sh


Running Julia application in a job
----------------------------------

Let's consider a standalone Julia application that contains the following files:

- :code:`Project.toml` for describing project metadata and dependencies.
- :code:`script.jl` for an entry point to run the desired Julia workload.
  Optionally, it can implement a command line client if we want to parse arguments that are supplied to the script.
- :code:`batch.sh` for a batch script for setting up the Julia environment and running the Julia workload.

.. demo:: Example of running Julia application on LUMI.

   We assume that our current working directory is the Julia application.
   Let's write our Julia script to file named ``script.jl``.

   .. code-block:: julia

      using Example
      hello("world")

   Our application depends on the Example.jl package, hence the ``Project.toml`` looks as follows:

   .. code-block:: toml

      [deps]
      Example = "7876af07-990d-54b4-ab0e-23690620f79a"

   We should instantiate the project enviroment on the login node.

   .. code-block:: console

      $ module use /appl/local/csc/modulefiles
      $ module load julia
      $ julia --project=. -e 'using Pkg; Pkg.instantiate()'

   Next we write the batch script to file named ``batch.sh``.
   It runs the Julia script using the Julia environment with predefined slurm parameters.

   .. code-block:: bash

      #!/bin/bash
      #SBATCH --account=project_465001310
      #SBATCH --partition=debug
      #SBATCH --nodes=1
      #SBATCH --ntasks-per-node=1
      #SBATCH --cpus-per-task=1
      #SBATCH --mem-per-cpu=1000
      #SBATCH --time="00:05:00"
      module use /appl/local/csc/modulefiles
      module load julia
      julia --project=. script.jl

   Finally, we can run the batch script using Slurm.

   .. code-block:: console

      $ sbatch batch.sh


Exercises
---------

In these exercises you should create the three files ``Project.toml``, ``script.jl``, and ``batch.sh`` and run them via Slurm in the LUMI cluster.
If the course has a resource reservation, we can use the :code:`--reservation="<name>"` option to use it.

.. exercise:: Run multithreaded job on LUMI cluster

   Run the following files in a single node job with two CPU cores and one julia thread per core.

   .. code-block:: toml
      :caption: ``Project.toml``

      # empty Project.toml

   .. code-block:: julia
      :caption: ``script.jl``

      using Base.Threads
      a = zeros(Int, 2*nthreads())
      @threads for i in eachindex(a)
          a[i] = threadid()
      end
      println(a)

   .. solution::

      .. code-block:: bash
         :caption: ``batch.sh``

         #!/bin/bash
         #SBATCH --account=project_465001310
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

      .. code-block:: console

         $ sbatch batch.sh


.. exercise:: Run single node distributed job on LUMI cluster

   Run the following files a single node job with three CPU cores and one julia process per core.

   .. code-block:: toml
      :caption: ``Project.toml``

      [deps]
      Distributed = "8ba89e20-285c-5b6f-9357-94700520ee1b"

   .. code-block:: julia
      :caption: ``script.jl``

      using Distributed
      addprocs(Sys.CPU_THREADS-1; exeflags="--project=.")

      @everywhere task() = myid()
      futures = [@spawnat id task() for id in workers()]
      outputs = fetch.(futures)
      println(outputs)

   .. solution::

      .. code-block:: bash
         :caption: ``batch.sh``

         #!/bin/bash
         #SBATCH --account=project_465001310
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

      .. code-block:: console

         $ sbatch batch.sh


.. exercise:: Run multi node distributed job on LUMI cluster

   .. attention::

      Currently ``SlurmManager`` gives errors on LUMI it tries to establish workers on multiple nodes.
      You may still test the code on single node.

   Run the following files on two node job with 128 tasks per node and one CPU code per task.
   Add Julia workers using ``SlurmManager`` from the ClusterManager.jl package.

   .. code-block:: toml
      :caption: ``Project.toml``

      [deps]
      ClusterManagers = "34f1f09b-3a8b-5176-ab39-66d58a4d544e"
      Distributed = "8ba89e20-285c-5b6f-9357-94700520ee1b"

   .. code-block:: julia
      :caption: ``script.jl``

      using Distributed
      using ClusterManagers
      proc_num = parse(Int, ENV["SLURM_NTASKS"])
      addprocs(SlurmManager(proc_num); exeflags="--project=.")

      @everywhere task() = myid()
      futures = [@spawnat id task() for id in workers()]
      outputs = fetch.(futures)
      println(outputs)

   .. solution::

      .. code-block:: bash
         :caption: ``batch.sh``

         #!/bin/bash
         #SBATCH --account=project_465001310
         #SBATCH --partition=standard
         #SBATCH --time=00:15:00
         #SBATCH --nodes=2
         #SBATCH --ntasks-per-node=128
         #SBATCH --cpus-per-task=1
         #SBATCH --mem-per-cpu=0

         module use /appl/local/csc/modulefiles
         module load julia
         julia --project=. -e 'using Pkg; Pkg.instantiate()'
         julia --project=. script.jl

      .. code-block:: console

         $ sbatch batch.sh


.. exercise:: Run MPI job on LUMI cluster

   Run the following files MPI code using two nodes with two slurm tasks per node and one CPU per task.

   .. code-block:: toml
      :caption: ``Project.toml``

      [deps]
      MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195"

   .. code-block:: julia
      :caption: ``script.jl``

      using MPI

      MPI.Init()
      comm = MPI.COMM_WORLD
      rank = MPI.Comm_rank(comm)
      size = MPI.Comm_size(comm)
      println("Hello from rank $(rank) out of $(size) from host $(gethostname()) and process $(getpid()).")
      MPI.Barrier(comm)

   .. solution::

      .. code-block:: bash
         :caption: ``batch.sh``

         #!/bin/bash
         #SBATCH --account=project_465001310
         #SBATCH --partition=small
         #SBATCH --nodes=2
         #SBATCH --ntasks-per-node=2
         #SBATCH --cpus-per-task=1
         #SBATCH --mem-per-cpu=1000
         #SBATCH --time="00:15:00"

         module use /appl/local/csc/modulefiles
         module load julia
         module load julia-mpi
         julia --project=. -e 'using Pkg; Pkg.instantiate()'
         srun julia --project=. script.jl

      .. code-block:: console

         $ sbatch batch.sh


.. exercise:: Run GPU job on LUMI cluster

   Run the following files GPU code using one node with one slurm tasks per node, one GPU per node and sixteen CPUs per task.

   .. code-block:: toml
      :caption: ``Project.toml``

      [deps]
      AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"

   .. code-block:: julia
      :caption: ``script.jl``

      using AMDGPU

      A = rand(2^9, 2^9)
      A_d = ROCArray(A)
      B_d = A_d * A_d

   .. solution::

      .. code-block:: bash
         :caption: ``batch.sh``

         #!/bin/bash
         #SBATCH --account=project_465001310
         #SBATCH --partition=small-g
         #SBATCH --time=00:15:00
         #SBATCH --nodes=1
         #SBATCH --ntasks-per-node=1
         #SBATCH --cpus-per-task=16
         #SBATCH --gpus-per-node=1
         #SBATCH --mem-per-cpu=1750

         module use /appl/local/csc/modulefiles
         module load julia
         module load julia-amdgpu
         julia --project=. -e 'using Pkg; Pkg.instantiate()'
         julia --project=. script.jl

      .. code-block:: console

         $ sbatch batch.sh

