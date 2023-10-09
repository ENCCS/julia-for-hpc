Distributed computing
=====================

.. questions::

   - How is multiprocessing used?
   - What are SharedArrays?

.. instructor-note::

   - 20 min teaching
   - 20 min exercises


Distributed computing
---------------------

Julia's main implementation of message passing for distributed-memory systems is contained in 
the ``Distributed`` module. Its approach is different from other frameworks like MPI in 
that communication is generally "one-sided", meaning that the programmer needs to explicitly 
manage only one process in a two-process operation. 
 
Julia can be started with a given number of `p local` workers using the ``-p``:

.. code-block:: bash

   julia -p 4

The ``Distributed`` module is automatically loaded if the ``-p`` flag is used.  
But we can also dynamically add processes in a running Julia session:

.. code-block:: julia

   using Distributed
   
   println(nprocs())
   addprocs(4)         # add 4 workers
   println(nprocs())   # total number of processes
   println(nworkers()) # only worker processes
   rmprocs(workers())  # remove worker processes


Note what happens here: there is one `master` process which can create 
additional `worker` processes, and as we shall see, it can also distribute work to these 
workers.

For running on a cluster, we instead need to provide the ``--machine-file`` option 
and the name of a file containing a list of machines that are accessible via 
password-less ``ssh``. Support for running on clusters with various schedulers 
(including SLURM) can be found in the 
`ClusterManagers.jl <https://github.com/JuliaParallel/ClusterManagers.jl>`_ 
package.

Each process has a unique identifier accessible via the ``myid()`` function (`master` 
has ``myid() = 1``). The ``@spawn`` and ``@spawnat`` macros can be used to transfer 
work to a process, and then return the resulting ``Future`` to the `master` process 
using the ``fetch`` function (``@spawn`` selects the process automatically while 
``@spawnat`` lets you choose: 

.. code-block:: julia

   # execute myid() and rand() on process 2
   r = @spawnat 2 (myid(), rand())
   # fetch the result
   fetch(r)

One use case could be to manually distribute expensive function calls 
between processes,
but there are higher-level and simpler constructs than ``@spawn`` / ``@spawnat``:

- the ``@distributed`` macro for ``for`` loops. Can be used with a 
  reduction operator to gather work performed by the independent tasks.
- the ``pmap`` function which maps an array or range to a given function.

To illustrate the difference between these approaches we revisit the 
``sum_sqrt`` function from the :doc:`multithreading` episode. To use ``pmap`` we need to modify our 
function to accept a range so we will use this modified version.
Note that to make any function available to all processes it needs to 
be decorated with the ``@everywhere`` macro:

.. tabs:: 

   .. tab:: Distributed version

      .. code-block:: julia
      
         @everywhere function sqrt_sum_range(A, r)
             s = zero(eltype(A))
             for i in r
                 @inbounds s += sqrt(A[i])
             end
             return s
         end

   .. tab:: Serial version

      .. code-block:: julia

         function sqrt_sum(A)
             s = zero(eltype(A))
             for i in eachindex(A)
                 @inbounds s += sqrt(A[i])
             end
             return s
         end

Let us look at and discuss example implementations using each of these 
techniques:

.. tabs:: 

   .. tab:: @distributed (+)

      .. code-block:: julia
      
         A = rand(100_000)
         batch = Int(length(A) / 100)

         @distributed (+) for r in [(1:batch) .+ offset for offset in 0:batch:length(A)-1]
             sqrt_sum_range(A, r)
         end


   .. tab:: pmap

      .. code-block:: julia

         A = rand(100_000)
         batch = Int(length(A) / 100)      

         sum(pmap(r -> sqrt_sum_range(A, r), [(1:batch) .+ offset for offset in 0:batch:length(A)-1]))


   .. tab:: @spawnat

      .. code-block::  julia
      
         futures = Array{Future}(undef, nworkers())
         A = rand(100_000)
         batch = Int(length(A) / 100)         
      
         @time begin
             for (i, id) in enumerate(workers())
                 batch = floor(Int, length(A) / nworkers())
                 remainder = length(A) % nworkers()
                 if (i-1) < remainder
                     start = 1 + (i - 1) * (batch + 1)
                     stop = start + batch
                 else 
                     start = 1 + (i - 1) * batch + remainder
                     stop = start + batch - 1
                 end
                 futures[i] = @spawnat myid() sqrt_sum_range(A, start:stop)
             end
             p = sum(fetch.(futures))
         end

The ``@spawnat`` version looks cumbersome for this case particular case as the algorithm 
required the explicit partitioning of the array which is common in MPI, for instance. 
The ``@distributed (+)`` parallel for loop and the ``pmap`` mapping are much simpler,
but which one is preferable for a given use case?

- ``@distributed`` is appropriate for reductions. It does not load-balance and 
  simply divides the work evenly between processes. It is best in cases where 
  each loop iteration is cheap.
- ``pmap`` can handle reductions as well as other algorithms. It performs load-balancing
  and since dynamic scheduling introduces some overhead it's best to use ``pmap`` 
  for computationally heavy tasks.
- In the case of ``@spawnat``, because the `futures` are not immediately using CPU
  resources, it opens the possibility of using asynchronous and uneven workloads.

.. callout:: Multiprocessing overhead

   Just like with multithreading, multiprocessing with ``Distributed`` comes with an overhead 
   because of sending messages and moving data between processes. 
   
   The simple example with the :meth:`sqrt_sum` function will not benefit from parallelisation. 
   But if you add a :meth:`sleep(0.001)` inside the loop, to emulate an expensive calculation, 
   and reduce array size to e.g. ``rand(1000)`` you should observe near-linear scaling. Try it!

Finally, it should be emphasized that a common use case of ``pmap`` involves heavy 
computations inside functions defined in imported packages. 
For example, computing the singular value decomposition of many matrices:

.. code-block:: julia

   @everywhere using LinearAlgebra
   x=[rand(100,100) for i in 1:10]
   @btime map(LinearAlgebra.svd, x);
   @btime pmap(LinearAlgebra.svd, x);


SharedArrays
^^^^^^^^^^^^

Shared arrays, supplied by the ``SharedArrays`` module in base Julia, are 
arrays that are shared across multiple processes on the same machine. They 
can be used to distribute operations on an array across processes.

Let us revisit the ``sqrt_array`` function and modify it to mutate the 
argument passed to it, and also add a method to it for 
SharedArrays which has the required ``@distributed`` and ``@sync`` macros  
(``@sync`` is needed to wait for all processes to finish):

.. tabs::

   .. tab:: Serial

      .. code-block:: julia
      
         function sqrt_array!(A)
             for i in eachindex(A)
                 @inbounds A[i] = sqrt(A[i])
             end
         end

   .. tab:: SharedArray

      .. code-block:: julia

         function sqrt_array!(A::SharedArray)
             @sync @distributed for i in eachindex(A)
                 @inbounds A[i] = sqrt(A[i])
             end
         end


Remember that Julia always selects the most specialized method for 
dispatch based on the argument type. We can now time these two methods 
using ``@time`` instead of ``@btime``, this time: 

.. code-block:: julia

   A = rand(100_000_000);
   @time sqrt_array!(A)

   SA = SharedArray(A);
   @time sqrt_array!(SA)


.. challenge:: Bonus questions
   
  - Should the ``@time`` expression be called more than once?
  - How can we check which method is being dispatched for ``A`` and ``SA``?

   .. solution::

      It is recommended to use ``@time`` several times to obtain better statistics
      and undermine the overhead of the initial run.

      One can check the method being displayed with the ``@which`` macro. 


We should keep in mind however that every change to a SharedArray causes message 
passing to keep them in sync between processes, and this can affect performance.


DistributedArrays
^^^^^^^^^^^^^^^^^

Another way to approach parallelization over multiple machines is through `DArray`s
from the `DistributedArrays.jl <https://github.com/JuliaParallel/DistributedArrays.jl>`_ package, 
which implements a *Global Array* interface. A `DArray` is distributed across a 
set of workers. Each worker can read and write from its local portion of the 
array and each worker has read-only access to the portions of the array held 
by other workers.

Currently, distributed arrays do not have much functionality 
and they requires significant book-keeping of array indices. 




Exercises
---------

.. exercise:: Using SharedArrays with the Laplace function

   Look again at the double for loop in the ``lap2d!`` function 
   and think about how you could use SharedArrays.

   .. solution:: Laplace and setup functions

      .. code-block:: julia

         function lap2d!(u, unew)
             M, N = size(u)
             for j in 2:N-1
                 for i in 2:M-1
                     unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
                 end 
             end
         end

         function lap2d!(u, unew)
             M, N = size(u)
             for j in 2:N-1
                 for i in 2:M-1
                     unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
                 end 
             end
         end


   - Create a new script where you import ``Distributed``, ``SharedArrays`` and 
     ``BenchmarkTools`` and define the ``lap2d!`` function.
   - Benchmark the original version:

   .. code-block:: julia

      u, unew = setup()
      @btime lap2d!(u, unew)

   - Now create a new method for this function which accepts SharedArrays. 
   - Add worker processes with ``addprocs`` and benchmark your new method 
     when passing in SharedArrays. Is there any performance gain? 

   - The overhead in managing the workers will probably far outweigh the 
     parallelization benefit because the computation in the inner loop is 
     very simple and fast.
   - Try adding ``sleep(0.001)`` to the **outermost** loop to simulate the effect 
     of a more demanding calculation, and rerun the benchmarking. Can you see a 
     speedup now?
   - Remember that you can remove worker processes with ``rmprocs(workers())``.


   .. solution:: 

      .. code-block:: Julia

         using BenchmarkTools
         using Distributed
         using SharedArrays
         
         function lap2d!(u, unew)
             M, N = size(u)
             for j in 2:N-1
                 for i in 2:M-1
                     @inbounds unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
                 end 
             end
         end
         
         function lap2d!(u::SharedArray, unew::SharedArray)
             M, N = size(u)
             @sync @distributed for j in 2:N-1
                 for i in 2:M-1
                     @inbounds unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
                 end 
             end
         end


         u, unew = setup()
         u_s = SharedArray(u);
         unew_s = SharedArray(unew);

         # test for correctness:
         lap2d!(u, unew) 
         lap2d!(u_s, unew_s) 
         # element-wise comparison, should give "true"
         all(u .≈ u_s)

         # benchmark
         @btime lap2d!(u, unew) 
         #   WRITEME

         @btime lap2d!(u_s, unew_s)
         #   WRITEME


.. exercise:: Distribute the computation of π

   .. figure:: img/pi_with_darts.png
      :scale: 7 %
      :align: right

   Consider again the :meth:`estimate_pi` function:

   .. literalinclude:: code/estimate_pi.jl
      :language: julia

   .. code-block:: julia

      num_points = 100_000_000
      estimate_pi(num_points)  # 3.14147572...

   Now try to parallelise this function using both a parallel mapping with :meth:`pmap` 
   and an ``@everywhere (+)`` construct. Write your code in a script which you can call with 
   ``julia -p N estimate_pi.jl``.

   - First decorate the function with ``@everywhere``.
   - Call it in serial with ``p1 = estimate_pi(num_points)``.
   - Use a list comprehension to split up ``num_points`` into evenly sized chunks in a Vector.  
     Hint: 
     
     .. code-block:: julia

       num_jobs = 100
       chunks = [____ / ____ for i in 1:____]

   - For parallel mapping, use ``p2 = mean(pmap(___, ___))`` to get the mean from a parallel mapping.
   - For a distributed for loop, use something like:

     .. code-block:: julia
   
        p3 = @distributed (+) for ____ in ____
           estimate_pi(____)
        end
        p3 = p3 / num_jobs

   - Print ``p1``, ``p2`` and ``p3`` to make sure that your code is working well.
   - Now do some benchmarking. You'll need to remove the assignments to use ``@btime`` 
     (e.g. replace ``p1 = estimate_pi(num_points))`` with ``@btime estimate_pi(num_points))``. 
     To benchmark the for loop, you can encapsulate the loop in a ``@btime begin`` - ``end`` block.
   - Run your script with different number of processes and observe the parallel efficiency.
   - Do you see a difference in parallel efficiency from changing the number of jobs?

   .. solution::

      .. literalinclude:: code/estimate_pi_distributed.jl      
         :language: julia 

      Set number of points and split into chunks:

      .. code-block:: julia

         num_points = 100_000_000
         num_jobs = 100
         chunks = [num_points / num_jobs for i in 1:num_jobs]

      Call :meth:`estimate_pi` in serial, with :meth:`pmap` and ``@distributed (+)``:

      .. code-block:: julia

         using Statistics 

         p1 = estimate_pi(num_points)
         p2 = mean(pmap(estimate_pi, chunks))
         p3 = @distributed (+) for c in chunks
            estimate_pi(c)
         end
         p3 = p3 / num_jobs

         println("$p1 $p2 $p3")


      Benchmark with ``@btime``:

      .. code-block:: julia

         using BenchmarkTools

         @btime estimate_pi(num_points)

         @btime mean(pmap(estimate_pi, chunks))

         @btime begin
             @distributed (+) for c in chunks
                 estimate_pi(c)
             end
         end   

      Finally run from a terminal:

      .. code-block:: console 

         $ julia -p 4 estimate_pi.jl

         #  227.873 ms (1 allocation: 16 bytes)
         #  63.707 ms (4602 allocations: 163.09 KiB)
         #  59.410 ms (259 allocations: 15.12 KiB)         

      Increasing number of jobs (``num_jobs = 1000``) reduces efficiency for the parallel mapping 
      because increased communication overhead:

      .. code-block:: console

         $ julia -p 4 estimate_pi.jl

         #  228.595 ms (1 allocation: 16 bytes)
         #  86.811 ms (45462 allocations: 1.57 MiB)
         #  59.480 ms (270 allocations: 43.61 KiB)


See also
--------

- The `Julia Parallel <https://github.com/JuliaParallel>`_ organization collects 
  packages developed for parallel computing in Julia.
- `MPI.jl <https://github.com/JuliaParallel/MPI.jl>`__
- `Distributed computing in Julia docs <https://docs.julialang.org/en/v1/manual/distributed-computing/>`__
- `Distributed API <https://docs.julialang.org/en/v1/stdlib/Distributed/>`__
- Valentin Churavy, `Levels of Parallelism <https://slides.com/valentinchuravy/julia-parallelism>`__

.. keypoints::

   - One should choose a distributed mechanism that fits with the 
     time and memory parameters of your problem.
   - ``@distributed`` is good for reductions and fast inner loops with limited 
     data transfer.
   - ``pmap`` is good for expensive inner loops that return a value.
   - ``SharedArrays`` can be an easier drop-in replacement for threading-like 
     behaviors on a single machine.
