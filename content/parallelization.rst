Parallelization
===============

.. questions::

   - What parallelization options exist in Julia?
   - What are the canonical ways of parallelizing on shared and distributed memory systems?

.. objectives::

   - Get an overview of parallelization in Julia
   - Learn to use the Threads module
   - Learn to use the Distributed package
   - Know when you can use ``@distributed`` and ``pmap``
   - Learn to work with SharedArrays and Distributed arrays

Overview
--------

WRITEME

Threading
---------

We will now walk through how to use multithreading in Julia. 
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
   JULIA_NUM_THREADS = 4 julia

This is not possible to do inside VSCode. Instead, we open up the 
"Extension Settings" for the Julia VSCode extension and set the 
"Julia: Num Threads" setting to the number of CPU cores we have on 
our machines (if you're unsure, just try setting it to 2).
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

   a = rand(1000, 1000)
   @btime sqrt_array(a);
   @btime threaded_sqrt_array(a);

   # make sure we're getting the correct value
   sqrt_array(a) ≈ threaded_sqrt_array(a)

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
             s
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


Threading with ``Threads.@threads`` is quite straightforward, 
but one needs to be careful not to introduce race conditions 
and sometimes that requires code refactorization. Using atomic operations 
adds significant overhead and thus only makes sense if each iteration 
of the loop takes significant time to compute.



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
   addprocs(4)
   println(nprocs())
   println(nworkers())


Note what happens here: there is one `master` process which can create 
additional `worker` processes, and as we shall see it can also distribute work to these 
workers.

For running on a cluster, we instead need to provide the ``--machine-file`` option 
and the name of a file containing a list of machines that are accessible via 
password-less ``ssh``.

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

   .. tab:: ``@distributed (+)``

      .. code-block:: julia
      
         batch = length(A) / 10
         @distributed (+) for r in [(1:batch) .+ offset for offset in 0:batch:length(A)-1]
             sqrt_sum_range(A, r)
         end


   .. tab:: ``pmap``

      .. code-block:: julia
      
         batch = length(A) / 10
         sum(pmap(r -> sqrt_sum_range(A, r), [(1:batch) .+ offset for offset in 0:batch:length(A)-1]))


   .. tab:: ``@spawnat``

      .. code-block:: 
      
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


SharedArrays
^^^^^^^^^^^^


DistributedArrays
^^^^^^^^^^^^^^^^^

notes
^^^^^

example function to distribute:

.. code-block:: julia

   @everywhere function compute_pi(N)
      series = 1.0
      for i in 1:N
         series += (isodd(i) ? -1 : 1) / (2i + 1)
      end
      return 4*series
   end

Summary
^^^^^^^

One should choose a distributed mechanism that fits with the 
time and memory parameters of your problem

- @distributed is good for reductions and even relatively fast inner loops with limited explicit data transfer
- pmap is good for expensive inner loops that return a value
- SharedArrays can be an easier drop-in replacement for threading-like behaviors (on a single machine)
- DistributedArrays lets the data do the work splitting



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
     in VSCode and relaunch the Julia REPL over and over, use the 
     `example.jl` script instead: comment out the visualization and 
     insert something like:

     .. code-block:: julia

        bench_results = @benchmark simulate!(curr, prev, nsteps)
        println(minimum(bench_results.times))

   - Now run with different number of threads from a terminal using 
     ``julia --project=. -t N example.jl`` and observe the scaling.
   - Try increasing the problem size (e.g. ``nx=ny=10_000``) while lowering the 
     number of time steps (e.g. ``nsteps = 20``). Does it scale better?


.. exercise:: Using SharedArrays with Heatequation

   Open up the Heatequation.jl package in VSCode and read the "SharedArrayHint"
   comments. Think about what you should do, and then try doing it.
   After you're done, benchmark a few test runs. 

   .. solution:: 

      Switch to the `SharedArrays` branch of the repository (``git checkout SharedArrays``)
      and have a look at the code.

.. exercise:: Using DistributedArrays with Heatequation

   Open up the Heatequation.jl package in VSCode and read the "DistributedArrayHint"
   comments. Think about what you should do, and then try doing it.
   After you're done, benchmark a few test runs.

   .. solution:: 

      Switch to the `DistributedArrays` branch of the repository (``git checkout DistributedArrays``)
      and have a look at the code.




See also
--------

- https://docs.julialang.org/en/v1/manual/multi-threading/
- https://julialang.org/blog/2019/07/multithreading/
- https://docs.julialang.org/en/v1/manual/performance-tips/
- https://docs.julialang.org/en/v1/manual/distributed-computing/

