Parallelization
===============

.. questions::

   - What parallelization options exist in Julia?
   - How is multithreading used?
   - How is multiprocessing used?
   - What are SharedArrays?

Overview
--------

Julia has inbuilt automatic parallelism which is useful to know about.
Consider the multiplication of two large array:

.. code-block:: julia

   A = rand(10000,10000)
   B = rand(10000,10000)
   A*B

If we run this in a Julia session and monitor the resource usage (e.g. via ``top``) 
we can see that all cores on our computers are used! 

But to beyond that, Julia supports four main types of parallel programming:

- **Asynchronous tasks or coroutines**: Tasks allow suspending and resuming 
  computations for I/O, event handling and similar patterns. Not really HPC and 
  outside the scope of the this lesson. 
- **Multi-threading**: Provides the ability to schedule Tasks simultaneously 
  on more than one thread or CPU core, sharing memory. The easiest way to parallelize 
  on shared-memory systems. Contained in the ``Threads`` standard library.
- **Distributed computing**: Runs multiple Julia processes with separate memory 
  spaces on the same or multiple computers. Useful high-level constructs are implemented 
  in the standard library ``Distributed`` module. For those that like MPI there is 
  `MPI.jl <https://github.com/JuliaParallel/MPI.jl>`_.
- **GPU computing**: Covered in the next episode!   
  

Threading
---------

We start by walking through how to use multithreading in Julia. 
In the VSCode REPL, let's see how many threads we have access to:

.. code-block:: julia

   Threads.nthreads()

Hmm, but we need more than one thread to be able to gain any performance 
from multithreading. 

Julia can be started with a given number of threads in two ways:

.. code-block:: bash

   julia -t 4  
   julia -t auto
   # or (can also set the env-var in e.g. .bashrc)
   JULIA_NUM_THREADS=4 julia

This is not possible to do inside VSCode. Instead, we open up the 
"Extension Settings" for the Julia VSCode extension and set the 
"Julia: Num Threads" setting to the number of CPU cores we have on 
our machines (if you're unsure, just try setting it to 2).
After updating the number of threads we need to restart the VSCode REPL.
We can make sure we have access to the correct number of threads 
with the ``Threads.nthreads()`` function.

The main multithreading approach is to use the ``Threads.@threads`` macro 
which parallelizes a `for` loop to run with multiple threads:

.. code-block:: julia

   using .Threads
   a = zeros(10)
   @threads for i = 1:10
       a[i] = threadid()
   end
   println(a)

Let's see if we can achieve any speed gain when performing a 
costly calculation.

.. tabs::

   .. tab:: Serial
   
      .. code-block:: julia

         function sqrt_array(A)
             B = similar(A)
             for i in eachindex(A)
                 @inbounds B[i] = sqrt(A[i])
             end
             B
         end
   
   .. tab:: Threaded
   
      .. code-block:: julia

         function threaded_sqrt_array(A)
             B = similar(A)
             @threads for i in eachindex(A)
                 @inbounds B[i] = sqrt(A[i])
             end
             B
         end

We can now compare the performance:

.. code-block:: julia

   A = rand(1000, 1000)
   @btime sqrt_array(A);
   @btime threaded_sqrt_array(A);

   # make sure we're getting the correct value
   sqrt_array(A) ≈ threaded_sqrt_array(A)

With 4 threads, the speedup could be between a factor 2 or 3.   


Pitfalls
^^^^^^^^

Just like with multithreading in other languages, one needs to be 
aware of possible `race conditions <https://en.wikipedia.org/wiki/Race_condition>`_, 
i.e. when the order in which threads read from and write to memory 
can change the result of a computation. 

We can illustrate this with an example where we sum up the square 
root of elements of an array. The serial version provides the correct 
value and reference execution time. The "race condition" version illustrates 
how a naive implementation can lead to problems. The "atomic" version shows 
how we can ensure a correct results by using `atomic operations`.
The "workaround" version shows how we can refactor the code to get both 
correct result and speedup.

.. tabs:: 

   .. tab:: Serial

      .. code-block:: julia

         function sqrt_sum(A)
             s = zero(eltype(A))
             for i in eachindex(A)
                 @inbounds s += sqrt(A[i])
             end
             return s
         end


   .. tab:: Race condition

      .. code-block:: julia

         function threaded_sqrt_sum(A)
             s = zero(eltype(A))
             @threads for i in eachindex(A)
                 @inbounds s += sqrt(A[i])
             end
             return s
         end

   .. tab:: Atomic

      .. code-block:: julia

         function threaded_sqrt_sum_atomic(A)
             s = Atomic{eltype(A)}(zero(eltype(A)))
             @threads for i in eachindex(A)
                 @inbounds atomic_add!(s, sqrt(A[i]))
             end
             return s[]
         end

   .. tab:: Workaround

      .. code-block:: julia

         function threaded_sqrt_sum_workaround(A)
             partial = zeros(eltype(A), nthreads())
             @threads for i in eachindex(A)
                 @inbounds partial[threadid()] += sqrt(A[i])
             end
             s = zero(eltype(A))
             for i in eachindex(partial)
                 s += partial[i]
             end     
             return s
         end         

We will observe that:

- The serial version is slow but correct.
- The race condition version is both slow and wrong.
- The atomic version is correct but extremely slow.
- The workaround is fast and correct, but required refactoring.

Bonus questions: 

- What does ``eltype`` do?
- What does ``eachindex`` do?

Threading with ``Threads.@threads`` is quite straightforward, 
but one needs to be careful not to introduce race conditions 
and sometimes that requires code refactorization. Using atomic operations 
adds significant overhead and thus only makes sense if each iteration 
of the loop takes significant time to compute.

FLoops
^^^^^^

`FLoops.jl <https://github.com/JuliaFolds/FLoops.jl>`__ is a a more recent  
package for threading. It provides a macro ``@floop`` which is a superset of ``Threads.@threads``
and can be used to generate fast generic sequential and parallel iteration over more 
complex collections than what can be done with ``Threads.@threads``.
``@floop`` can also do reductions and supports multiple threading backends through 
`FoldsThreads.jl <FoldsThreads.jl>`_ and even `FoldsCUDA.jl 
<https://github.com/JuliaFolds/FoldsCUDA.jl>`__ for running on GPUs.



Distributed computing
---------------------

Julia's main implementation of message passing for distributed-memory systems is contained in 
the ``Distributed`` module. Its approach is different from other frameworks like MPI in 
that communication is generally "one-sided", meaning that the programmer needs to explicitly 
manage only one process in a two-process operation. 
 
Julia can be started with a given number of `local` processes using the ``-p``:

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
additional `worker` processes, and as we shall see it can also distribute work to these 
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
``sum_sqrt`` function from above. To use ``pmap`` we need to modify our 
function to accept a range so we will use this modified version.
Note that to make any function available to all processes it needs to 
be decorated with the ``@everywhere`` macro:

.. code-block:: julia

   @everywhere function sqrt_sum_range(A, r)
       s = zero(eltype(A))
       for i in r
           @inbounds s += sqrt(A[i])
       end
       return s
   end

Let us look at and discuss example implementations using each of these 
techniques:

.. tabs:: 

   .. tab:: @distributed (+)

      .. code-block:: julia
      
         batch = length(A) / 10

         @distributed (+) for r in [(1:batch) .+ offset for offset in 0:batch:length(A)-1]
             sqrt_sum_range(A, r)
         end


   .. tab:: pmap

      .. code-block:: julia
      
         batch = length(A) / 10

         sum(pmap(r -> sqrt_sum_range(A, r), [(1:batch) .+ offset for offset in 0:batch:length(A)-1]))


   .. tab:: @spawnat

      .. code-block::  julia
      
         futures = Array{Future}(undef, nworkers())
      
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

The ``@spawnat`` version is cumbersome to use in this case and the algorithm 
required to partition the array reminds of MPI. 
The ``@distributed (+)`` parallel for loop and the ``pmap`` mapping are much simpler,
but which one is preferable for a given use case?

- ``@distributed`` is appropriate for reductions. It does not load-balance and 
  simply divides the work evenly between processes. It is best in cases where 
  each loop iteration is cheap.
- ``pmap`` can handle reductions as well as other algorithms. It performs load-balancing
  and since dynamic scheduling introduces some overhead it's best to use ``pmap`` 
  for computationally heavy tasks.

It should be emphasized that a common use case of ``pmap`` involves heavy 
computations inside functions defined in user-imported packages. 
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

Bonus questions:

- Should the ``@time`` expression be called more than once?
- How can we check which method is being dispatched for ``A`` and ``SA``?

We should keep in mind however that every change to a SharedArray causes message 
passing to keep them in sync between processes, and this can affect performance.


DistributedArrays
^^^^^^^^^^^^^^^^^

Another way to approach parallelization over multiple machines is through 
`DistributedArrays.jl <https://github.com/JuliaParallel/DistributedArrays.jl>`_, 
which implements a *Global Array* interface. A DArray is distributed across a 
set of workers. Each worker can read and write from its local portion of the 
array and each worker has read-only access to the portions of the array held 
by other workers.

Currently, distributed arrays do not have much functionality 
and they requires significant book-keeping of array indices. 


MPI
^^^

`MPI.jl <https://github.com/JuliaParallel/MPI.jl>`_ is a Julia interface to 
the Message Passing Interface, which has been the standard workhorse of 
parallel computing for decades. If you know how to parallelize a program 
with MPI in any other languages, you know how to do it in Julia!



Exercises
---------

.. exercise:: Multithreading HeatEquation.jl

   Consider the double for loop in the ``evolve!`` function. 
   Can it safely be threaded, i.e. is there any risk of race 
   conditions?

   - Insert the ``Threads.@threads`` macro in the right location - 
     note that ``@threads`` currently only works on outermost loops!
   - Measure its effects with ``@benchmark``.
     Since it's cumbersome to change the "Julia: Num Threads" option 
     in VSCode and relaunch the Julia REPL over and over, create a script instead 
     which imports `HeatEquation` and `BenchmarkTools` and prints benchmark 
     results:      

     .. code-block:: julia

        bench_results = @benchmark simulate!(curr, prev, nsteps)
        println(minimum(bench_results.times))

   - Now run with different number of threads from a terminal using 
     ``julia --project=. -t <N> benchmarking.jl`` and observe the scaling.
   - Try increasing the problem size (e.g. ``nx=ny=10_000``) while lowering the 
     number of time steps (e.g. ``nsteps = 20``). Does it scale better?

   .. solution::

      Threaded version of ``evolve!``:

      .. code-block:: julia

         function evolve!(curr::Field, prev::Field, a, dt)
             Threads.@threads for j = 2:curr.ny+1
                 for i = 2:curr.nx+1
                     @inbounds xderiv = (prev.data[i-1, j] - 2.0 * prev.data[i, j] + prev.data[i+1, j]) / curr.dx^2
                     @inbounds yderiv = (prev.data[i, j-1] - 2.0 * prev.data[i, j] + prev.data[i, j+1]) / curr.dy^2
                     @inbounds curr.data[i, j] = prev.data[i, j] + a * dt * (xderiv + yderiv)
                 end 
             end
         end

      Script to run benchmarking:

      .. code-block:: julia
 
         using HeatEquation
         using BenchmarkTools
         
         ncols, nrows, nsteps = 10_000, 10_000, 20
         curr, prev = initialize(ncols, nrows)
         
         bench_results = @benchmark simulate!(curr, prev, nsteps)
         # minimum runtime in seconds
         println(minimum(bench_results.times)/1e9)

      Running benchmarking from terminal:

      .. code-block:: bash

         $ julia --project -t 1 run_benchmarking.jl
         # 5.314849396
         $ julia --project -t 2 run_benchmarking.jl
         # 3.236433742
         $ julia --project -t 4 run_benchmarking.jl
         # 3.311189835
       
      The scaling isn't very good because the loops in ``evolve!`` are very cheap, 
      but it seems to scale better with larger arrays.



.. exercise:: Using SharedArrays with HeatEquation

   Look again at the double for loop in the ``evolve!`` function 
   and think about how you could use SharedArrays.

   The best approach might be to start by refactoring the package a bit and change 
   the ``evolve!`` function to accept arrays instead of ``Field`` structs, like this:

   .. code-block:: julia

      function evolve!(currdata::AbstractArray, prevdata::AbstractArray, dx, dy, a, dt)
          nx, ny = size(currdata) .- 2
          for j = 2:ny+1
              for i = 2:nx+1
                  @inbounds xderiv = (prevdata[i-1, j] - 2.0 * prevdata[i, j] + prevdata[i+1, j]) / dx^2
                  @inbounds yderiv = (prevdata[i, j-1] - 2.0 * prevdata[i, j] + prevdata[i, j+1]) / dy^2
                  @inbounds currdata[i, j] = prevdata[i, j] + a * dt * (xderiv + yderiv)
              end 
          end
      end 

   - Create a new script where you import ``Distributed``, ``SharedArrays`` and 
     ``BenchmarkTools`` and define the ``evolve!`` function above.
   - Benchmark the original version:

   .. code-block:: julia

      dx = dy = 0.01
      a = 0.5
      dt = dx^2 * dy^2 / (2.0 * a * (dx^2 + dy^2))
      M1 = rand(1000, 1000);
      M2 = rand(1000, 1000);
      @btime evolve!(M1, M2, dx, dy, a, dt)

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

         function evolve!(currdata::AbstractArray, prevdata::AbstractArray, dx, dy, a, dt)
             nx, ny = size(currdata) .- 2
             for j = 2:ny+1
                 for i = 2:nx+1
                     @inbounds xderiv = (prevdata[i-1, j] - 2.0 * prevdata[i, j] + prevdata[i+1, j]) / dx^2
                     @inbounds yderiv = (prevdata[i, j-1] - 2.0 * prevdata[i, j] + prevdata[i, j+1]) / dy^2
                     @inbounds currdata[i, j] = prevdata[i, j] + a * dt * (xderiv + yderiv)
                 end 
                 sleep(0.001)
             end
         end

         function evolve!(currdata::SharedArray, prevdata::SharedArray, dx, dy, a, dt)
             nx, ny = size(currdata) .- 2
             @sync @distributed for j = 2:ny+1
                 for i = 2:nx+1
                     @inbounds xderiv = (prevdata[i-1, j] - 2.0 * prevdata[i, j] + prevdata[i+1, j]) / dx^2
                     @inbounds yderiv = (prevdata[i, j-1] - 2.0 * prevdata[i, j] + prevdata[i, j+1]) / dy^2
                     @inbounds currdata[i, j] = prevdata[i, j] + a * dt * (xderiv + yderiv)
                 end 
                 sleep(0.001)
             end
         end

         dx = dy = 0.01
         a = 0.5
         dt = dx^2 * dy^2 / (2.0 * a * (dx^2 + dy^2))
         M1 = rand(1000, 1000);
         M2 = rand(1000, 1000);
         S1 = SharedArray(M1);
         S2 = SharedArray(M2);

         # test for correctness:
         evolve!(M1, M2, dx, dy, a, dt) 
         evolve!(S1, S2, dx, dy, a, dt) 
         # element-wise comparison, should give "true"
         all(M1 .≈ S1)

         # benchmark
         @btime evolve!(M1, M2, dx, dy, a, dt) 
         #   2.379 s (5031 allocations: 152.52 KiB)

         @btime evolve!(S1, S2, dx, dy, a, dt)
         #   578.060 ms (722 allocations: 32.72 KiB)


.. exercise:: Parallel mapping

   .. figure:: img/pi_with_darts.png
      :scale: 7 %
      :align: right

   Consider the following function which estimates π by "throwing darts", 
   i.e. randomly sampling (x,y) points in the interval [0.0, 1.0] and checking 
   if they fall within the unit circle.

   .. code-block:: julia

      function estimate_pi(num_points)
          hits = 0
          for _ in 1:num_points
              x, y = rand(), rand()
              if x^2 + y^2 < 1.0
                  hits += 1
              end
          end
          fraction = hits / num_points
          return 4 * fraction
      end

      num_points = 100_000_000
      estimate_pi(num_points)  # 3.14147572...

   - Rewrite the function to accept a UnitRange (``1:10`` is a UnitRange{Int64})
     and decorate it with ``@everywhere``.
   - Use a list comprehension to split up ``num_points`` into evenly sized chunks
     (Hint: ``[(___:___) .+ ___ for ___ in ___:___:___]``).
   - Add worker processes as needed.
   - Use ``mean(pmap(___, ___))`` to get the mean from a parallel mapping 
     distributed among the workers.
   - Do some benchmarking, and try varying the chunk size from small (each process 
     gets a small task and there's more communication) to large (larger amount of work 
     for each worker and smaller communication).

     .. solution::

        .. code-block:: julia

           using Distributed
           using BenchmarkTools
   
           function estimate_pi(num_points)
               hits = 0
               for _ in 1:num_points
                   x, y = rand(), rand()
                   if x^2 + y^2 < 1.0
                       hits += 1
                   end
               end
               fraction = hits / num_points
               return 4 * fraction
           end
           
           @everywhere function estimate_pi(range::UnitRange)
               hits = 0
               for _ in range
                   x, y = rand(), rand()
                   if x^2 + y^2 < 1.0
                       hits += 1
                   end
               end
               fraction = hits / length(range)
               return 4 * fraction
           end
           
           
           num_points = 100_000_000
           @btime estimate_pi(num_points)
           # 366.751 ms (1 allocation: 16 bytes)
           
           # splitting into ~10-50 chunks seems to be close to a sweet spot for 4 workers
           # chunk = 100_000  # too much communication overhead
           chunk = 10_000_000
           ranges = [(1:chunk) .+ offset for offset in 0:chunk:num_points-1]
           
           @btime mean(pmap(estimate_pi, ranges))
           # 151.578 ms (572 allocations: 20.61 KiB)

See also
--------

- The `Julia Parallel <https://github.com/JuliaParallel>`_ organization collects 
  packages developed for parallel computing in Julia.
- `Multi-threading docs <https://docs.julialang.org/en/v1/manual/multi-threading/>`__
- `MPI.jl <https://github.com/JuliaParallel/MPI.jl>`__
- `Distributed computing in Julia docs <https://docs.julialang.org/en/v1/manual/distributed-computing/>`__
- `Distributed API <https://docs.julialang.org/en/v1/stdlib/Distributed/>`__
- Valentin Churavy, `Levels of Parallelism <https://slides.com/valentinchuravy/julia-parallelism>`__

.. keypoints::

   - One should choose a distributed mechanism that fits with the 
     time and memory parameters of your problem   
   - ``Threads`` is as easy as decorating for loops with ``@threads``, but data 
     dependencies (race conditions) need to be avoided.
   - ``@distributed`` is good for reductions and fast inner loops with limited 
     data transfer.
   - ``pmap`` is good for expensive inner loops that return a value.
   - ``SharedArrays`` can be an easier drop-in replacement for threading-like 
     behaviors on a single machine.
