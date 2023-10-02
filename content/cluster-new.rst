Using Julia on HPC cluster
==========================

.. questions::

   - How do we run Julia a HPC cluster?
   - How can we do parallel computing with Julia on HPC cluster?

.. instructor-note::

   - 30 min teaching
   - 30 min exercises

Julia on HPC systems
--------------------
Despite rapid growth in the HPC domain in recent years, Julia is still not considered as mainstream as C/C++ and Fortran in the HPC world, and even Python is more commonly used (and generally available) than Julia.
Fortunately, even if Julia is not already available as an environment module on your favorite cluster, it is easy to install Julia from scratch.
Moreover, there is little reason to expect the performance of official Julia binaries to be any worse than if a system administrator built Julia from scratch with architecture-specific optimization.
`Julia on HPC clusters <https://juliahpc.github.io/JuliaOnHPCClusters/>`_ gives an overview of the availability and documentation of Julia on a range of HPC systems around the world including EuroHPC systems.


Components of a HPC cluster
---------------------------
HPC cluster consists of networked computers called **nodes**.
The nodes are separated into user facing **login nodes** and nodes that are inteded for heavy computing called **compute nodes**
The nodes are colocated and connected using a **high-speed network** minimize communication latency and maximize performance at scale.
A **parallel file system** provides a system-wide mass storage capacity.

HPC clusters use the **Linux operating system**.
Many problems that users have of using a cluster stem from lack of Linux knowledge.

Clusters also use **module environments** to manage software environments by setting enviroment variables and load other modules as dependencies.
We demonstrate the popular **Lmod** software and how to use Julia module environments with Lmod.

Finally, HPC clusters use a **workload manager** to manage resources and to run jobs on compute nodes.
We demonstrate the popular **Slurm** workload manager and how to run Julia programs that perform various forms of parallel computing with Slurm.


Using module enviroments
------------------------
We can load a shared Julia installation as a module environment if one is available.
The module environment modifies the path to the make the Julia command line client available and may set environment variables for Julia threads counts and modify the depot and load paths to make shared packages available.

Available module enviroments are controlled by the module path (:code:`MODULEPATH`) environment variable.
Sometimes, it is necessary to add custom directories to the module path as follows:

.. code-block:: bash

   module use <path>

We can check the availability of a Julia module environment as follows.

.. code-block:: bash

   module avail julia

If Julia module is not available, we can install Julia manually to the cluster.
On the otherhand, if a Julia module is available, we can take a look at what the Julia sets when it is loaded as follows:

.. code-block:: bash

   module show julia

We can load the Julia module as follows:

.. code-block:: bash

   module load julia

We can list loaded moduel and check that Julia is available as follows:

.. code-block:: bash

   module list
   julia --version

In case everything works well, we should be ready to move forward.

.. tabs::

   .. tab:: LUMI CPU

      .. code-block::

          module use /appl/local/csc/modulefiles
          module load julia

   .. tab:: LUMI GPU

      .. code-block::

          module use /appl/local/csc/modulefiles
          module load julia-amdgpu


Running an interactive job
--------------------------
We can launch an interactive job on a compute node via Slurm.
Interactive jobs are useful for developing, testing, debugging, and exploring slurm jobs.
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


Running a batch job
-------------------
We can run batch jobs via Slurm.
We use batch jobs to run workloads from start to finish without interacting with them.
We can run a batch job as follows:

.. code-block:: bash

   sbatch [options] script.sh

The :code:`sbatch` command launches the batch job, with options that declare the resources we want to reserve and the :code:`script.sh` is the script we run.

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


Installing packages
-------------------


Exercises
---------
Run estimate pi using multithreading, multiprocesses and MPI.

